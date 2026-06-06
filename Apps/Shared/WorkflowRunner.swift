import AICoScientistFoundationModels
import AICoScientistKit
import AICoScientistMLX
import AICoScientistRemote
import Foundation
import Observation
import SwiftData

/// Coordinates the single active run and publishes live, granular state to SwiftUI. One run at a
/// time. State is a reduced `RunState` (M22): the run orchestrator dispatches `RunAction`s through
/// the pure `runReducer`; this type projects the state for the views (same accessor names as
/// before, so views are unchanged). Side-effects (model loading, the engine, thermal cancel) live
/// here, not in the reducer. On completion the result is persisted back onto the `Study`.
@MainActor
@Observable
final class WorkflowRunner {
    /// The single source of truth for the live run; mutated only via `runReducer`.
    private(set) var state = RunState()

    private var task: Task<Void, Never>?

    /// Kept for `ChartsView`'s existing parameter type; the Elo trend point now lives in the Kit.
    typealias ProgressPoint = EloTimelinePoint

    // Projections the views read (unchanged call sites).
    var runningStudyID: UUID? { state.runningStudyID }
    var status: String { state.status }
    var phase: String { state.phase }
    var detail: String { state.detail }
    var completed: Int { state.completed }
    var total: Int { state.total }
    var hypotheses: [Hypothesis] { state.hypotheses }
    var metrics: ExecutionMetrics { state.metrics }
    var errors: [String] { state.errors }
    var activity: [ActivityEvent] { state.activity }
    var downloadProgress: Double? { state.downloadProgress }
    var downloadingNeeded: Bool { state.downloadingNeeded }
    var iteration: Int { state.iteration }
    var maxIterations: Int { state.maxIterations }
    var timeline: [EloTimelinePoint] { state.timeline }

    var running: Bool { state.runningStudyID != nil }
    var phaseFraction: Double? { state.phaseFraction }

    func isRunning(_ study: Study) -> Bool { state.runningStudyID == study.id }

    private func apply(_ action: RunAction) { state = runReducer(state, action) }

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
        guard state.runningStudyID == nil else { return }
        let downloadingNeeded = downloadPlan(for: study).contains {
            if case .proceed(let bytes, _) = $0.decision, bytes > 0 { return true }
            return false
        }
        apply(.started(
            studyID: study.id, maxIterations: study.iterations,
            downloadingNeeded: downloadingNeeded,
            status: downloadingNeeded
                ? "Downloading models from Hugging Face…" : "Loading models…"))
        let id = study.id
        task = Task { await self.run(study: study, context: context, id: id) }
    }

    func cancel() {
        task?.cancel()
        apply(.status("Cancelling…"))
    }

    private func run(study: Study, context: ModelContext, id: UUID) async {
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
                        apply(.status("Not enough free memory for \(model.displayName) "
                            + "(~\(freeMB) MB free). Pick a smaller model or close other apps."))
                        study.status = .error
                        study.updatedAt = Date()
                        try? context.save()
                        if state.runningStudyID == id { apply(.cleared) }
                        return
                    }
                }
            #endif

            // Pre-load each distinct on-device model (async), cached by key.
            var onDevice: [String: any SchemaConstrainedDecoding] = [:]
            func ensureOnDevice(_ key: String) async throws {
                guard onDevice[key] == nil else { return }
                let model = try await MLXLanguageModel.load(key) { [weak self] fraction in
                    Task { @MainActor in self?.apply(.downloadProgress(fraction)) }
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
                Task { @MainActor in self?.apply(.downloadProgress(fraction)) }
            }
            apply(.downloadProgress(nil))

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

            apply(.status("Running…"))
            let result = await engine.run(researchGoal: study.goal) { [weak self] progress in
                Task { @MainActor in self?.applyProgress(progress) }
            }

            let cancelled = result.errors.contains { $0.localizedCaseInsensitiveContains("cancel") }
            let produced = !result.topRankedHypotheses.isEmpty
            let issues = result.errors.count
            let status: String
            if cancelled {
                status = "Cancelled · "
                    + RunStatusText.count(result.topRankedHypotheses.count, "hypothesis", "hypotheses")
                    + " so far"
            } else if !produced {
                status = "No hypotheses produced · "
                    + RunStatusText.count(issues, "issue", "issues") + " — see Issues"
            } else if issues > 0 {
                status = String(
                    format: "Done with %@ · %.1fs",
                    RunStatusText.count(issues, "issue", "issues"), result.totalWorkflowTime)
            } else {
                status = String(
                    format: "Done · %.1fs · %@ · %@", result.totalWorkflowTime,
                    RunStatusText.count(result.metrics.repairAttempts, "repair", "repairs"),
                    RunStatusText.count(result.metrics.decodeFailures, "decode failure", "decode failures"))
            }
            apply(.finished(
                status: status, hypotheses: result.topRankedHypotheses,
                metrics: result.metrics, errors: result.errors))

            var snapshot = RunSnapshot(researchGoal: study.goal, result: result)
            snapshot.activity = state.activity
            study.snapshot = snapshot
            study.status = cancelled ? .draft : (produced ? .done : .error)
        } catch {
            apply(.status("Error: \(error)"))
            study.status = .error
        }
        study.updatedAt = Date()
        try? context.save()
        if state.runningStudyID == id { apply(.cleared) }
    }

    /// Apply a progress action, then the mid-run thermal side-effect (stop cleanly on critical).
    private func applyProgress(_ progress: WorkflowProgress) {
        apply(.progress(progress))
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
