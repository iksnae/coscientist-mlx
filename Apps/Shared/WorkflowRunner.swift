import AICoScientistFoundationModels
import AICoScientistKit
import AICoScientistMLX
import AICoScientistRemote
import Foundation
import Observation
import SwiftData

/// Coordinates the single active run and publishes live, granular state to SwiftUI. One run at
/// a time; the detail view shows live state only while `runningStudyID` matches the study it's
/// displaying. On completion the result is persisted back onto the `Study`.
@MainActor
@Observable
final class WorkflowRunner {
    private(set) var runningStudyID: UUID?
    private(set) var status = "Idle"
    private(set) var phase = ""
    private(set) var detail = ""
    private(set) var completed = 0
    private(set) var total = 0
    private(set) var hypotheses: [Hypothesis] = []
    private(set) var metrics = ExecutionMetrics()
    private(set) var errors: [String] = []
    private(set) var activity: [ActivityEvent] = []
    private(set) var downloadProgress: Double?
    private(set) var timeline: [ProgressPoint] = []

    private var task: Task<Void, Never>?
    private var activityStep = 0

    struct ProgressPoint: Identifiable, Sendable {
        let id = UUID()
        let step: Int
        let phase: String
        let topElo: Int
        let avgElo: Double
        let poolSize: Int
    }

    var running: Bool { runningStudyID != nil }
    var phaseFraction: Double? { total > 0 ? Double(completed) / Double(total) : nil }

    func isRunning(_ study: Study) -> Bool { runningStudyID == study.id }

    /// Disk decisions for this study's models (so the UI can confirm or block before download).
    /// Uses the actually-selected on-device Generator (hosted choices download nothing) plus the
    /// embedder, which always runs on-device.
    func downloadPlan(for study: Study) -> [(name: String, decision: DownloadGuard.Decision)] {
        var keys: [String] = []
        if case .onDevice(let key) = study.generator { keys.append(key) }
        keys.append(SettingsStore.shared.embedderKey)
        return keys.map { key in
            (ModelCatalog.model(key: key)?.displayName ?? key, DownloadGuard.decide(forKeyOrID: key))
        }
    }

    func start(study: Study, context: ModelContext) {
        guard runningStudyID == nil else { return }
        runningStudyID = study.id
        let id = study.id
        task = Task { await self.run(study: study, context: context, id: id) }
    }

    func cancel() {
        task?.cancel()
        status = "Cancelling…"
    }

    private func run(study: Study, context: ModelContext, id: UUID) async {
        status = "Loading models (first run downloads from Hugging Face)…"
        phase = ""; detail = ""; completed = 0; total = 0
        hypotheses = []; errors = []; activity = []; metrics = ExecutionMetrics()
        timeline = []; downloadProgress = nil; activityStep = 0
        study.status = .running

        let settings = SettingsStore.shared
        do {
            let decodeMetrics = DecodeMetrics()

            // Per-study model selection: the Generator backs generation/evolution/ranking/
            // meta-review; the Reviewer backs reflection + tournament. A hosted choice falls
            // back to on-device when no provider is configured (local-first).
            let apiKey = settings.openAIKey
            let baseURL = URL(string: settings.remoteBaseURL)
                ?? URL(string: "https://api.openai.com/v1")!
            func sanitize(_ choice: ModelChoice) -> ModelChoice {
                (choice.isHosted && !settings.remoteReady)
                    ? .onDevice(ModelCatalog.defaultGeneratorKey) : choice
            }
            let generatorChoice = sanitize(study.generator)
            let reviewerChoice = sanitize(study.reviewer)

            // On-device safety (iOS): cap the GPU buffer cache + block a doomed run on low memory.
            #if os(iOS)
                MLXRuntime.setGPUCacheLimit(bytes: 24 * 1024 * 1024)
                if case .onDevice(let key) = generatorChoice,
                    let model = ModelCatalog.model(key: key) {
                    let freeMB = Int(os_proc_available_memory() / (1024 * 1024))
                    if RunGuard.memory(freeMB: freeMB, modelApproxGB: model.approxSizeGB) == .block {
                        status = "Not enough free memory for \(model.displayName) "
                            + "(~\(freeMB) MB free). Pick a smaller model or close other apps."
                        study.status = .error
                        study.updatedAt = Date()
                        try? context.save()
                        if runningStudyID == id { runningStudyID = nil }
                        return
                    }
                }
            #endif

            // Pre-load each distinct on-device model (async), cached by key.
            var onDevice: [String: any SchemaConstrainedDecoding] = [:]
            func ensureOnDevice(_ key: String) async throws {
                guard onDevice[key] == nil else { return }
                let model = try await MLXLanguageModel.load(key) { [weak self] fraction in
                    Task { @MainActor in self?.downloadProgress = fraction }
                }
                onDevice[key] = SchemaConstrainedDecoder(model: model, metrics: decodeMetrics)
            }
            if case .onDevice(let key) = generatorChoice { try await ensureOnDevice(key) }
            if case .onDevice(let key) = reviewerChoice { try await ensureOnDevice(key) }

            func makeHosted(_ id: String) -> any SchemaConstrainedDecoding {
                SchemaConstrainedDecoder(
                    model: RemoteLanguageModel(model: id, apiKey: apiKey, baseURL: baseURL),
                    metrics: decodeMetrics)
            }
            let makeOnDevice: (String) -> any SchemaConstrainedDecoding = { key in
                onDevice[key] ?? makeHosted(key)  // both choices are pre-loaded; fallback is dead
            }

            let embedder = try await MLXEmbeddingModel.load(settings.embedderKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            downloadProgress = nil

            let router = StudyRouting.router(
                generator: generatorChoice, reviewer: reviewerChoice,
                makeOnDevice: makeOnDevice, makeHosted: makeHosted)

            let engine = CoScientistEngine(
                router: router,
                config: .init(
                    maxIterations: study.iterations,
                    hypothesesPerGeneration: study.hypothesesPerGeneration,
                    tournamentRoundsPerHypothesis: study.tournamentRounds,
                    evolutionTopK: study.evolutionTopK),
                proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder),
                decodeMetrics: decodeMetrics)

            status = "Running…"
            let result = await engine.run(researchGoal: study.goal) { [weak self] progress in
                Task { @MainActor in self?.apply(progress) }
            }

            hypotheses = result.topRankedHypotheses
            metrics = result.metrics
            errors = result.errors
            let cancelled = result.errors.contains { $0.localizedCaseInsensitiveContains("cancel") }
            let produced = !result.topRankedHypotheses.isEmpty
            let issues = result.errors.count
            phase = "done"; detail = ""; completed = 0; total = 0
            if cancelled {
                status = "Cancelled · \(result.topRankedHypotheses.count) hypotheses so far"
            } else if !produced {
                // A finished run with no hypotheses is a failure, not "Done" — say so loudly.
                status = "No hypotheses produced · \(issues) issue\(issues == 1 ? "" : "s") — see Issues"
            } else if issues > 0 {
                status = String(
                    format: "Done with %d issue(s) · %.1fs", issues, result.totalWorkflowTime)
            } else {
                status = String(
                    format: "Done · %.1fs · %d repairs · %d decode failures",
                    result.totalWorkflowTime, result.metrics.repairAttempts,
                    result.metrics.decodeFailures)
            }

            var snapshot = RunSnapshot(researchGoal: study.goal, result: result)
            snapshot.activity = activity
            study.snapshot = snapshot
            study.status = cancelled ? .draft : (produced ? .done : .error)
        } catch {
            status = "Error: \(error)"
            study.status = .error
        }
        study.updatedAt = Date()
        try? context.save()
        if runningStudyID == id { runningStudyID = nil }
    }

    private func apply(_ progress: WorkflowProgress) {
        phase = progress.phase
        detail = progress.detail
        completed = progress.completed
        total = progress.total
        hypotheses = progress.hypotheses
        metrics = progress.metrics
        activity.append(ActivityEvent(step: activityStep, progress: progress))
        activityStep += 1
        if activity.count > 200 { activity.removeFirst(activity.count - 200) }

        if !progress.hypotheses.isEmpty {
            let elos = progress.hypotheses.map(\.eloRating)
            timeline.append(
                ProgressPoint(
                    step: timeline.count, phase: progress.phase,
                    topElo: elos.max() ?? 1200,
                    avgElo: Double(elos.reduce(0, +)) / Double(elos.count),
                    poolSize: elos.count))
        }

        // Mid-run thermal safety: stop cleanly (via the cancel path) on critical thermal state.
        let thermal: DeviceThermalState
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = .nominal
        case .fair: thermal = .fair
        case .serious: thermal = .serious
        case .critical: thermal = .critical
        @unknown default: thermal = .nominal
        }
        if RunGuard.thermal(thermal) == .stop { cancel() }
    }
}
