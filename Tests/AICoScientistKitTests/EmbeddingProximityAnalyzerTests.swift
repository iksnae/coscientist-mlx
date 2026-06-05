import Testing
@testable import AICoScientistKit

/// A mock embedding model returning canned vectors keyed by text, so the analyzer can be
/// exercised deterministically without MLX.
private struct MockEmbeddingModel: EmbeddingModel {
    let vectors: [String: [Float]]
    func embed(_ texts: [String]) async throws -> [[Float]] {
        texts.map { vectors[$0] ?? [0, 0] }
    }
}

@Suite("Embedding proximity analyzer")
struct EmbeddingProximityAnalyzerTests {

    @Test("Clusters similar hypotheses by embedding and assigns stable IDs")
    func clustersBySimilarity() async throws {
        let h1 = Hypothesis(text: "solar")
        let h2 = Hypothesis(text: "solar-ish")
        let h3 = Hypothesis(text: "wind")
        let model = MockEmbeddingModel(vectors: [
            "solar": [1, 0],
            "solar-ish": [1, 0],   // identical → same cluster as solar
            "wind": [0, 1],        // orthogonal → its own cluster
        ])
        let analyzer = EmbeddingProximityAnalyzer(model: model, threshold: 0.9)
        let clusters = try await analyzer.cluster([h1, h2, h3])

        #expect(clusters.count == 2)
        let solarCluster = clusters.first { $0.memberIDs.contains(h1.id) }
        #expect(solarCluster?.memberIDs.contains(h2.id) == true)
        #expect(solarCluster?.memberIDs.contains(h3.id) == false)
    }

    @Test("Empty input yields no clusters")
    func empty() async throws {
        let analyzer = EmbeddingProximityAnalyzer(model: MockEmbeddingModel(vectors: [:]))
        #expect(try await analyzer.cluster([]).isEmpty)
    }

    @Test("Engine uses an injected embedding analyzer for the proximity phase")
    func enginePluggable() async {
        // Generation makes two hypotheses; the embedding analyzer (not the LLM agent) clusters them.
        let model = ScriptedProximityModel()
        let embedder = MockEmbeddingModel(vectors: ["Hypothesis Alpha": [1, 0], "Hypothesis Beta": [1, 0]])
        let engine = CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: model),
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2, tournamentSize: 2, evolutionTopK: 2),
            seed: 1,
            proximityAnalyzer: EmbeddingProximityAnalyzer(model: embedder, threshold: 0.9)
        )
        let result = await engine.run(researchGoal: "g")
        // Both evolved hypotheses share an embedding → a single cluster from the embedding path.
        #expect(result.errors.isEmpty)
        #expect(result.clusters.count == 1)
    }
}

/// Scripted model whose generation/evolution keep the two texts identical so the embedding
/// mock can key on them through the iteration.
private struct ScriptedProximityModel: LanguageModel {
    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String {
        if system.contains("Hypothesis Generation Agent") {
            return #"{"hypotheses":[{"text":"Hypothesis Alpha","justification":"j"},{"text":"Hypothesis Beta","justification":"j"}]}"#
        }
        if system.contains("Hypothesis Reflection Agent") {
            // Batched reflection returns one review per hypothesis; the engine applies prefix(poolSize).
            let review = #"{"scores":{"scientificSoundness":0.8,"novelty":0.7,"relevance":0.75,"testability":0.9,"clarity":0.8,"impact":0.6},"reviewSummary":"ok","safetyEthicalConcerns":"None identified","strengths":[],"weaknesses":[],"suggestions":[]}"#
            return #"{"reviews":[\#(review),\#(review),\#(review),\#(review)]}"#
        }
        if system.contains("Hypothesis Evolution Agent") {
            // Keep the text stable across evolution so the embedding mock still matches.
            return #"{"originalText":"o","refinedText":"Hypothesis Alpha","refinementSummary":"s"}"#
        }
        if system.contains("Meta-Review Agent") {
            return #"{"metaReviewSummary":"m","strengths":[],"weaknesses":[],"strategicRecommendations":[]}"#
        }
        if system.contains("Tournament Judge Agent") {
            return #"{"winner":"a","rationale":"r"}"#
        }
        return "{}"
    }
}
