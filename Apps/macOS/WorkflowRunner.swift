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
    private(set) var activity: [String] = []
    private(set) var downloadProgress: Double?
    private(set) var timeline: [ProgressPoint] = []

    private var task: Task<Void, Never>?

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
        timeline = []; downloadProgress = nil
        study.status = .running

        let settings = SettingsStore.shared
        do {
            let model = try await MLXLanguageModel.load(study.generatorKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            let embedder = try await MLXEmbeddingModel.load(settings.embedderKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            downloadProgress = nil
            let decodeMetrics = DecodeMetrics()
            let localDecoder = SchemaConstrainedDecoder(model: model, metrics: decodeMetrics)

            let router: any DecoderRouting
            if study.useRemoteJudge, settings.remoteReady, let baseURL = URL(string: settings.remoteBaseURL) {
                let remote = RemoteLanguageModel(
                    model: settings.remoteModel, apiKey: settings.openAIKey, baseURL: baseURL)
                let remoteDecoder = SchemaConstrainedDecoder(model: remote, metrics: decodeMetrics)
                router = RoleDecoderRouter(
                    default: localDecoder,
                    overrides: [.reflection: remoteDecoder, .tournament: remoteDecoder])
            } else {
                router = StaticDecoderRouter(localDecoder)
            }

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

            study.snapshot = RunSnapshot(researchGoal: study.goal, result: result)
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
        let line =
            "[iter \(progress.iteration)] \(progress.phase)"
            + (progress.detail.isEmpty ? "" : " · \(progress.detail)")
        activity.append(line)
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
