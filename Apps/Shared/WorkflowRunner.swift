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
    func downloadPlan(for study: Study) -> [(name: String, decision: DownloadGuard.Decision)] {
        [study.generatorKey, SettingsStore.shared.embedderKey].map { key in
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

            // Hosted per-agent backings (gated by the study's "Use hosted models" toggle).
            var backends: [AgentRole: RoleBackend] = [:]
            let remoteBaseURL = URL(string: settings.remoteBaseURL)
            if study.useRemoteJudge, settings.remoteReady, remoteBaseURL != nil {
                backends = settings.roleBackends
                if backends.isEmpty {
                    // No explicit per-agent picks → classic reflection + tournament judge split.
                    backends = [
                        .reflection: .remote(settings.remoteModel),
                        .tournament: .remote(settings.remoteModel),
                    ]
                }
            }
            let apiKey = settings.openAIKey
            let makeRemote: (String) -> any SchemaConstrainedDecoding = { id in
                SchemaConstrainedDecoder(
                    model: RemoteLanguageModel(
                        model: id, apiKey: apiKey,
                        baseURL: remoteBaseURL ?? URL(string: "https://api.openai.com/v1")!),
                    metrics: decodeMetrics)
            }

            // The local generator backs every role not assigned a hosted model. Skip loading it
            // entirely when all roles are hosted (e.g. the "Hosted all" preset) — no wasted download.
            let allRolesHosted =
                !backends.isEmpty && AgentRole.allCases.allSatisfy { backends[$0] != nil }
            let defaultDecoder: any SchemaConstrainedDecoding
            if allRolesHosted {
                defaultDecoder = makeRemote(settings.remoteModel)
            } else {
                let model: any LanguageModel
                let effectiveBackend = InferenceBackend.resolve(
                    requested: settings.backend,
                    foundationAvailable: FoundationModelsBackend.isAvailable)
                if effectiveBackend == .foundation, let fm = FoundationModelsBackend.makeModel() {
                    model = fm  // on-device Apple model; no download
                } else {
                    model = try await MLXLanguageModel.load(study.generatorKey) { [weak self] fraction in
                        Task { @MainActor in self?.downloadProgress = fraction }
                    }
                }
                defaultDecoder = SchemaConstrainedDecoder(model: model, metrics: decodeMetrics)
            }

            let embedder = try await MLXEmbeddingModel.load(settings.embedderKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            downloadProgress = nil

            let router: any DecoderRouting =
                backends.isEmpty
                ? StaticDecoderRouter(defaultDecoder)
                : RoleDecoderRouter.backed(
                    default: defaultDecoder, backends: backends, makeRemote: makeRemote)

            let engine = CoScientistEngine(
                router: router,
                config: .init(
                    maxIterations: study.iterations,
                    hypothesesPerGeneration: study.hypothesesPerGeneration),
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
            phase = "done"; detail = ""; completed = 0; total = 0
            status = cancelled
                ? "Cancelled · \(result.topRankedHypotheses.count) hypotheses so far"
                : String(
                    format: "Done · %.1fs · %d repairs · %d decode failures",
                    result.totalWorkflowTime, result.metrics.repairAttempts,
                    result.metrics.decodeFailures)

            var snapshot = RunSnapshot(researchGoal: study.goal, result: result)
            snapshot.activity = activity
            study.snapshot = snapshot
            study.status = cancelled ? .draft : .done
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
    }
}
