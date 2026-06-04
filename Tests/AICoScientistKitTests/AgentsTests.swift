import Testing
@testable import AICoScientistKit

/// Each agent is exercised through a MockLanguageModel + the real SchemaConstrainedDecoder,
/// so these tests cover prompt construction, the schema contract, and typed decoding —
/// deterministically and without MLX.
@Suite("Agents")
struct AgentsTests {

    private func decoder(_ json: String) -> SchemaConstrainedDecoder {
        SchemaConstrainedDecoder(model: MockLanguageModel(constant: json))
    }

    @Test("Generation: produces typed hypotheses; prompt carries goal and count")
    func generation() async throws {
        let agent = GenerationAgent()
        #expect(agent.userPrompt(for: .init(researchGoal: "fusion", count: 3)).contains("fusion"))
        #expect(agent.userPrompt(for: .init(researchGoal: "fusion", count: 3)).contains("3"))
        let out = try await agent.run(
            .init(researchGoal: "fusion", count: 1),
            using: decoder(#"{"hypotheses":[{"text":"H1","justification":"novel"}]}"#))
        #expect(out.hypotheses.first?.text == "H1")
    }

    @Test("Reflection: decodes a HypothesisReview")
    func reflection() async throws {
        let agent = ReflectionAgent()
        #expect(agent.userPrompt(for: .init(researchGoal: "g", hypothesisText: "H")).contains("H"))
        let json = #"""
        {"scores":{"scientificSoundness":0.8,"novelty":0.7,"testability":0.9,"impact":0.6},
         "reviewSummary":"good","strengths":["a"],"weaknesses":[],"suggestions":["b"]}
        """#
        let out = try await agent.run(.init(researchGoal: "g", hypothesisText: "H"), using: decoder(json))
        #expect(out.scores.novelty == 0.7)
        #expect(out.reviewSummary == "good")
    }

    @Test("Ranking: decodes ordered hypotheses; prompt numbers them")
    func ranking() async throws {
        let agent = RankingAgent()
        #expect(agent.userPrompt(for: .init(hypotheses: ["x", "y"])).contains("1. x"))
        let out = try await agent.run(
            .init(hypotheses: ["x"]),
            using: decoder(#"{"ranked":[{"text":"x","overallScore":0.9,"rankingExplanation":"best"}]}"#))
        #expect(out.ranked.first?.overallScore == 0.9)
    }

    @Test("Evolution: decodes refined hypothesis")
    func evolution() async throws {
        let agent = EvolutionAgent()
        let out = try await agent.run(
            .init(originalText: "o", reviewFeedback: "f", metaReviewInsights: "m"),
            using: decoder(#"{"originalText":"o","refinedText":"r","refinementSummary":"s"}"#))
        #expect(out.refinedText == "r")
    }

    @Test("Meta-review: decodes synthesis with recommendations")
    func metaReview() async throws {
        let agent = MetaReviewAgent()
        let out = try await agent.run(
            .init(reviewsDigest: "digest"),
            using: decoder(#"{"metaReviewSummary":"sum","strengths":["x"],"weaknesses":["y"],"strategicRecommendations":["z"]}"#))
        #expect(out.metaReviewSummary == "sum")
        #expect(out.strategicRecommendations == ["z"])
    }

    @Test("Tournament: decodes a verdict; prompt carries both hypotheses")
    func tournament() async throws {
        let agent = TournamentAgent()
        let prompt = agent.userPrompt(for: .init(researchGoal: "g", hypothesisA: "AAA", hypothesisB: "BBB"))
        #expect(prompt.contains("AAA") && prompt.contains("BBB"))
        let out = try await agent.run(
            .init(researchGoal: "g", hypothesisA: "AAA", hypothesisB: "BBB"),
            using: decoder(#"{"winner":"b","rationale":"stronger"}"#))
        #expect(out.winner == .b)
    }

    @Test("Proximity: decodes index-based clusters")
    func proximity() async throws {
        let agent = ProximityAgent()
        #expect(agent.userPrompt(for: .init(hypotheses: ["a", "b"])).contains("0. a"))
        let out = try await agent.run(
            .init(hypotheses: ["a", "b"]),
            using: decoder(#"{"clusters":[{"clusterID":"c1","clusterName":"n","memberIndices":[0,1]}]}"#))
        #expect(out.clusters.first?.memberIndices == [0, 1])
    }

    @Test("All agents expose a non-empty name and system prompt")
    func metadata() {
        #expect(!GenerationAgent().systemPrompt.isEmpty && !GenerationAgent().name.isEmpty)
        #expect(!ReflectionAgent().systemPrompt.isEmpty && !ReflectionAgent().name.isEmpty)
        #expect(!RankingAgent().systemPrompt.isEmpty && !RankingAgent().name.isEmpty)
        #expect(!EvolutionAgent().systemPrompt.isEmpty && !EvolutionAgent().name.isEmpty)
        #expect(!MetaReviewAgent().systemPrompt.isEmpty && !MetaReviewAgent().name.isEmpty)
        #expect(!TournamentAgent().systemPrompt.isEmpty && !TournamentAgent().name.isEmpty)
        #expect(!ProximityAgent().systemPrompt.isEmpty && !ProximityAgent().name.isEmpty)
    }
}
