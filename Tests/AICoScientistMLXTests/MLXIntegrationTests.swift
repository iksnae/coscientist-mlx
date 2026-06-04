import AICoScientistKit
import Foundation
import Testing

@testable import AICoScientistMLX

// Opt-in real-model integration tests (RUN_MLX_INTEGRATION=1).

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

    @Test("Schema-constrained decode validates a real model's verdict against the schema")
    func schemaConstrainedDecode() async throws {
        let model = try await MLXLanguageModel.load()
        let decoder = SchemaConstrainedDecoder(model: model)
        // No hand-written JSON instructions: the schema is injected automatically.
        let verdict = try await decoder.decode(
            TournamentJudgment.self,
            system: "You are a careful scientific judge.",
            user: "A: Water boils at 100°C at sea level. B: Water boils at 5°C at sea level. Which is sounder?",
            config: .deterministic
        )
        #expect(verdict.winner == .a || verdict.winner == .b)
        #expect(!verdict.rationale.isEmpty)
    }

    @Test("Embedding model produces normalized vectors that cluster related texts")
    func embeddingProximity() async throws {
        let model = try await MLXEmbeddingModel.load()
        let related = Hypothesis(text: "Solar panel efficiency improves with anti-reflective coatings.")
        let alsoSolar = Hypothesis(text: "Anti-reflective coatings raise photovoltaic panel efficiency.")
        let unrelated = Hypothesis(text: "Gut microbiota composition influences mood regulation.")

        let analyzer = EmbeddingProximityAnalyzer(model: model, threshold: 0.6)
        let clusters = try await analyzer.cluster([related, alsoSolar, unrelated])

        // The two solar hypotheses should share a cluster; the microbiome one should not.
        let solarCluster = clusters.first { $0.memberIDs.contains(related.id) }
        #expect(solarCluster?.memberIDs.contains(alsoSolar.id) == true)
        #expect(solarCluster?.memberIDs.contains(unrelated.id) == false)
    }
}
