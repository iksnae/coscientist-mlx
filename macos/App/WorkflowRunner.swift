import AICoScientistKit
import AICoScientistMLX
import Foundation
import Observation

/// Drives a workflow run and publishes live state to SwiftUI. The engine's `onProgress`
/// callback (invoked off the main actor) hops back here to update the UI as each phase lands.
@MainActor
@Observable
final class WorkflowRunner {
    var goal = "Improve lithium-ion battery energy density"
    var hypothesesPerGeneration = 4
    var iterations = 1

    private(set) var running = false
    private(set) var status = "Idle"
    private(set) var phase = ""
    private(set) var hypotheses: [Hypothesis] = []
    private(set) var metrics = ExecutionMetrics()
    private(set) var errors: [String] = []

    func run() async {
        running = true
        status = "Loading models (first run downloads from Hugging Face)…"
        phase = ""
        hypotheses = []
        errors = []
        metrics = ExecutionMetrics()

        do {
            let model = try await MLXLanguageModel.load()
            let embedder = try await MLXEmbeddingModel.load()
            let decodeMetrics = DecodeMetrics()
            let engine = CoScientistEngine(
                decoder: SchemaConstrainedDecoder(model: model, metrics: decodeMetrics),
                config: .init(
                    maxIterations: iterations, hypothesesPerGeneration: hypothesesPerGeneration),
                proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder),
                decodeMetrics: decodeMetrics)

            status = "Running…"
            let result = await engine.run(researchGoal: goal) { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    self.phase = progress.phase
                    self.hypotheses = progress.hypotheses
                    self.metrics = progress.metrics
                    self.status =
                        "iteration \(progress.iteration) · \(progress.phase) · "
                        + "\(progress.hypotheses.count) hypotheses"
                }
            }

            hypotheses = result.topRankedHypotheses
            metrics = result.metrics
            errors = result.errors
            phase = "done"
            status = String(
                format: "Done · %.1fs · %d repairs · %d decode failures",
                result.totalWorkflowTime, result.metrics.repairAttempts,
                result.metrics.decodeFailures)
        } catch {
            status = "Error: \(error)"
        }
        running = false
    }
}
