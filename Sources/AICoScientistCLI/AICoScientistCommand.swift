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

    @Flag(help: "Load the local MLX model and generate a single sample (downloads ~4.5 GB on first run).")
    var probe = false

    mutating func run() async throws {
        print("coscientist-mlx \(BuildInfo.version)")
        print("Research goal: \(goal)")

        guard probe else {
            print("M1 inference is wired. Re-run with --probe to load the model and generate.")
            print("(The full agent engine lands in M4.)")
            return
        }

        print("Loading local model (first run downloads from Hugging Face)…")
        let model = try await MLXLanguageModel.load()
        let reply = try await model.generateText(
            system: "You are a terse scientific assistant. Propose one concise, testable hypothesis.",
            user: goal,
            config: .deterministic
        )
        print("\n--- model output ---\n\(reply)")
    }
}
