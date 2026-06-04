import AICoScientistKit
import Foundation
import Testing

@testable import AICoScientistMLX

/// Real-model integration tests. These download a model (~4.5 GB) and run on the GPU, so
/// they are OPT-IN: set `RUN_MLX_INTEGRATION=1` to enable. Normal `swift test` and CI skip
/// them. Unit-level behaviour is covered MLX-free in AICoScientistKitTests.
@Suite(
    "MLX integration",
    .enabled(if: ProcessInfo.processInfo.environment["RUN_MLX_INTEGRATION"] == "1")
)
struct MLXIntegrationTests {

    @Test("Loads the default model and generates non-empty text")
    func generatesText() async throws {
        let model = try await MLXLanguageModel.load()
        let text = try await model.generateText(
            system: "You are terse.",
            user: "Reply with the single word: hello",
            config: .deterministic
        )
        #expect(!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    @Test("Structured decode yields a typed verdict from a real model")
    func structuredDecode() async throws {
        let model = try await MLXLanguageModel.load()
        let decoder = LanguageModelStructuredDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self,
            system: #"You are a judge. Respond ONLY with JSON: {"winner":"a" or "b","rationale":"..."}."#,
            user: "A: Water boils at 100°C at sea level. B: Water boils at 5°C at sea level. Which is sounder?",
            config: .deterministic
        )
        #expect(verdict.winner == .a || verdict.winner == .b)
    }
}
