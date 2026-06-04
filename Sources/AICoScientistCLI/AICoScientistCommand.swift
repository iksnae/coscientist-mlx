import AICoScientistKit
import AICoScientistMLX
import ArgumentParser

@main
struct AICoScientistCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aicoscientist",
        abstract: "Multi-agent scientific hypothesis generation on Apple Silicon (MLX)."
    )

    @Argument(help: "The research goal to explore.")
    var goal: String

    @Flag(help: "Run the full multi-agent workflow (downloads ~4.5 GB on first run).")
    var run = false

    @Flag(help: "Load the model and generate a single sample instead of the full workflow.")
    var probe = false

    @Option(help: "Refinement iterations after the initial round.")
    var iterations = 2

    @Option(help: "Hypotheses to generate initially.")
    var count = 6

    mutating func run() async throws {
        print("coscientist-mlx \(BuildInfo.version)")
        print("Research goal: \(goal)\n")

        if probe {
            try await runProbe()
        } else if run {
            try await runWorkflow()
        } else {
            print("Pass --run for the full workflow, or --probe for a single sample.")
        }
    }

    private func runProbe() async throws {
        print("Loading local model (first run downloads from Hugging Face)…")
        let model = try await MLXLanguageModel.load()
        let reply = try await model.generateText(
            system: "You are a terse scientific assistant. Propose one concise, testable hypothesis.",
            user: goal,
            config: .deterministic
        )
        print("\n--- model output ---\n\(reply)")
    }

    private func runWorkflow() async throws {
        print("Loading local models (first run downloads from Hugging Face)…")
        let model = try await MLXLanguageModel.load()
        let embedder = try await MLXEmbeddingModel.load()
        let engine = CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: model),
            config: .init(maxIterations: iterations, hypothesesPerGeneration: count),
            proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder)
        )

        print("Running workflow…\n")
        let result = await engine.run(researchGoal: goal)

        print("--- Top hypotheses (by Elo) ---")
        for (rank, h) in result.topRankedHypotheses.enumerated() {
            print("\(rank + 1). [elo \(h.eloRating), score \(String(format: "%.2f", h.score))] \(h.text)")
        }
        print("\n--- Metrics ---")
        print("hypotheses=\(result.metrics.hypothesisCount) reviews=\(result.metrics.reviewsCount) "
            + "matches=\(result.metrics.tournamentsCount) evolutions=\(result.metrics.evolutionsCount)")
        print(String(format: "time=%.1fs", result.totalWorkflowTime))
        if !result.errors.isEmpty {
            print("\n--- Errors (\(result.errors.count)) ---")
            result.errors.forEach { print("• \($0)") }
        }
    }
}
