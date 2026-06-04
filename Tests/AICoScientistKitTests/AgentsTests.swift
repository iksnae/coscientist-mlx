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
        {"scores":{"scientificSoundness":0.8,"novelty":0.7,"relevance":0.75,"testability":0.9,"clarity":0.8,"impact":0.6},
         "reviewSummary":"good","safetyEthicalConcerns":"None identified",
         "strengths":["a"],"weaknesses":[],"suggestions":["b"]}
        """#
        let out = try await agent.run(.init(researchGoal: "g", hypothesisText: "H"), using: decoder(json))
        #expect(out.scores.novelty == 0.7)
        #expect(out.scores.relevance == 0.75)
        #expect(out.scores.clarity == 0.8)
        #expect(out.reviewSummary == "good")
        #expect(out.safetyEthicalConcerns == "None identified")
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

    @Test("Evolution: decodes refined hypothesis with specific refinements")
    func evolution() async throws {
        let agent = EvolutionAgent()
        let json = #"""
        {"originalText":"o","refinedText":"r","refinementSummary":"s",
         "specificRefinements":[{"aspect":"clarity","change":"tightened","justification":"was vague"}]}
        """#
        let out = try await agent.run(
            .init(originalText: "o", reviewFeedback: "f", metaReviewInsights: "m"), using: decoder(json))
        #expect(out.refinedText == "r")
        #expect(out.specificRefinements.first?.aspect == "clarity")
    }

    @Test("Meta-review: decodes the enriched synthesis (themes, process, connections)")
    func metaReview() async throws {
        let agent = MetaReviewAgent()
        let json = #"""
        {"metaReviewSummary":"sum","recurringThemes":["t1"],"strengths":["x"],"weaknesses":["y"],
         "processAssessment":{"generation":"g","review":"r","evolution":"e"},
         "strategicRecommendations":["z"],"potentialConnections":["c1"]}
        """#
        let out = try await agent.run(.init(reviewsDigest: "digest"), using: decoder(json))
        #expect(out.metaReviewSummary == "sum")
        #expect(out.recurringThemes == ["t1"])
        #expect(out.processAssessment.evolution == "e")
        #expect(out.potentialConnections == ["c1"])
        #expect(out.strategicRecommendations == ["z"])
    }

    @Test("Meta-review: terse reply (only summary) still decodes with defaults")
    func metaReviewLenient() async throws {
        let out = try await MetaReviewAgent().run(
            .init(reviewsDigest: "d"), using: decoder(#"{"metaReviewSummary":"only"}"#))
        #expect(out.metaReviewSummary == "only")
        #expect(out.recurringThemes.isEmpty)
        #expect(out.processAssessment == .init())
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
