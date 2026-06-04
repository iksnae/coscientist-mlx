import AICoScientistKit
import ArgumentParser

@main
struct AICoScientistCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "aicoscientist",
        abstract: "Multi-agent scientific hypothesis generation on Apple Silicon (MLX)."
    )

    @Argument(help: "The research goal to explore.")
    var goal: String

    mutating func run() async throws {
        print("coscientist-mlx \(BuildInfo.version)")
        print("Research goal: \(goal)")
        print("M0 foundation only — inference (M1) and the engine (M4) are not yet wired.")
    }
}
