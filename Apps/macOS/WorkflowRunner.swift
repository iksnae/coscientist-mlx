import AICoScientistKit
import AICoScientistMLX
import AICoScientistRemote
import Foundation
import Observation

/// Drives a workflow run and publishes live, granular state to SwiftUI. The engine's
/// `onProgress` callback (invoked off the main actor, per phase and per sub-step) hops back
/// here to update the UI as each review/match/evolution lands.
@MainActor
@Observable
final class WorkflowRunner {
    var goal = "Improve lithium-ion battery energy density"
    var hypothesesPerGeneration = 4
    var iterations = 1

    private(set) var running = false
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

    /// A point in the run's Elo timeline, captured after each phase/sub-step.
    struct ProgressPoint: Identifiable, Sendable {
        let id = UUID()
        let step: Int
        let phase: String
        let topElo: Int
        let avgElo: Double
        let poolSize: Int
    }

    private var lastResult: WorkflowResult?
    private var task: Task<Void, Never>?

    /// Progress within the current phase (0…1), or nil when there's nothing countable.
    var phaseFraction: Double? { total > 0 ? Double(completed) / Double(total) : nil }

    /// A completed run is available to export.
    var canExport: Bool { lastResult != nil && !running }

    /// Start a run (no-op if one is in flight). Held as a Task so it can be cancelled.
    func start() {
        guard !running else { return }
        task = Task { await self.run() }
    }

    /// Request cancellation of the in-flight run.
    func cancel() {
        task?.cancel()
        status = "Cancelling…"
    }

    private func run() async {
        running = true
        status = "Loading models (first run downloads from Hugging Face)…"
        phase = ""; detail = ""; completed = 0; total = 0
        hypotheses = []; errors = []; activity = []; metrics = ExecutionMetrics()
        timeline = []; lastResult = nil; downloadProgress = nil

        let store = SettingsStore.shared
        do {
            let model = try await MLXLanguageModel.load(store.generatorKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            let embedder = try await MLXEmbeddingModel.load(store.embedderKey) { [weak self] fraction in
                Task { @MainActor in self?.downloadProgress = fraction }
            }
            downloadProgress = nil
            let decodeMetrics = DecodeMetrics()
            let localDecoder = SchemaConstrainedDecoder(model: model, metrics: decodeMetrics)

            let router: any DecoderRouting
            if store.remoteReady, let baseURL = URL(string: store.remoteBaseURL) {
                let remote = RemoteLanguageModel(
                    model: store.remoteModel, apiKey: store.openAIKey, baseURL: baseURL)
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
                    maxIterations: iterations, hypothesesPerGeneration: hypothesesPerGeneration),
                proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder),
                decodeMetrics: decodeMetrics)

            status = "Running…"
            let result = await engine.run(researchGoal: goal) { [weak self] progress in
                Task { @MainActor in self?.apply(progress) }
            }

            hypotheses = result.topRankedHypotheses
            metrics = result.metrics
            errors = result.errors
            lastResult = result
            phase = "done"; detail = ""; completed = 0; total = 0
            let cancelled = result.errors.contains { $0.localizedCaseInsensitiveContains("cancel") }
            status = cancelled
                ? "Cancelled · \(result.topRankedHypotheses.count) hypotheses so far"
                : String(
                    format: "Done · %.1fs · %d repairs · %d decode failures",
                    result.totalWorkflowTime, result.metrics.repairAttempts,
                    result.metrics.decodeFailures)
        } catch {
            status = "Error: \(error)"
        }
        running = false
    }

    /// Build an exportable snapshot of the most recent run.
    func makeSnapshot() -> RunSnapshot? {
        lastResult.map { RunSnapshot(researchGoal: goal, result: $0) }
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
                    step: timeline.count,
                    phase: progress.phase,
                    topElo: elos.max() ?? 1200,
                    avgElo: Double(elos.reduce(0, +)) / Double(elos.count),
                    poolSize: elos.count))
        }
    }
}
