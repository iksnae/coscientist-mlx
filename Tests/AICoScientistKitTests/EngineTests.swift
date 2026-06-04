import Testing
@testable import AICoScientistKit

/// A mock model that answers each agent according to its system prompt, enabling a full,
/// deterministic engine run with no MLX and no downloads.
private struct ScriptedModel: LanguageModel {
    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String {
        if system.contains("Hypothesis Generation Agent") {
            return #"{"hypotheses":[{"text":"Hypothesis Alpha","justification":"j"},{"text":"Hypothesis Beta","justification":"j"}]}"#
        }
        if system.contains("Hypothesis Reflection Agent") {
            return #"{"scores":{"scientificSoundness":0.8,"novelty":0.7,"testability":0.9,"impact":0.6},"reviewSummary":"solid","strengths":["s"],"weaknesses":["w"],"suggestions":["fix"]}"#
        }
        if system.contains("Hypothesis Evolution Agent") {
            return #"{"originalText":"o","refinedText":"Refined Hypothesis","refinementSummary":"s"}"#
        }
        if system.contains("Meta-Review Agent") {
            return #"{"metaReviewSummary":"Synthesis complete","strengths":["s"],"weaknesses":["w"],"strategicRecommendations":["r"]}"#
        }
        if system.contains("Tournament Judge Agent") {
            return #"{"winner":"a","rationale":"clearer"}"#
        }
        if system.contains("Proximity Agent") {
            return #"{"clusters":[{"clusterID":"c1","clusterName":"theme","memberIndices":[0]}]}"#
        }
        return "{}"
    }
}

/// A model that never returns parseable JSON — used to verify graceful degradation.
private struct BrokenModel: LanguageModel {
    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String {
        "I cannot help with that."
    }
}

@Suite("CoScientistEngine")
struct EngineTests {

    private func smallEngine(model: LanguageModel, seed: UInt64 = 42) -> CoScientistEngine {
        CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: model),
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2,
                          tournamentSize: 2, evolutionTopK: 1),
            seed: seed
        )
    }

    @Test("Full workflow produces ranked hypotheses with no errors")
    func happyPath() async {
        let result = await smallEngine(model: ScriptedModel()).run(researchGoal: "test goal")
        #expect(result.errors.isEmpty)
        #expect(result.topRankedHypotheses.count == 1)            // evolutionTopK=1 narrows the pool
        #expect(result.topRankedHypotheses.first?.text == "Refined Hypothesis")
        #expect(result.metaReviewSummary == "Synthesis complete")
    }

    @Test("Metrics count the phases that ran")
    func metrics() async {
        let result = await smallEngine(model: ScriptedModel()).run(researchGoal: "test goal")
        #expect(result.metrics.hypothesisCount == 2)              // generation
        #expect(result.metrics.reviewsCount == 3)                 // 2 initial + 1 after evolution
        #expect(result.metrics.tournamentsCount == 6)             // 2 hypotheses * 3 rounds (post-evo pool of 1 skips)
        #expect(result.metrics.evolutionsCount == 1)
    }

    @Test("Evolved hypothesis carries its lineage")
    func lineage() async {
        let result = await smallEngine(model: ScriptedModel()).run(researchGoal: "test goal")
        let evolved = result.topRankedHypotheses.first
        #expect(evolved?.evolutionHistory.count == 1)
        #expect(evolved?.evolutionHistory.first?.contains("Hypothesis") == true)
    }

    @Test("Proximity assigns clusters by index")
    func clusters() async {
        let result = await smallEngine(model: ScriptedModel()).run(researchGoal: "test goal")
        #expect(result.clusters.count == 1)
        #expect(result.clusters.first?.clusterID == "c1")
        #expect(result.topRankedHypotheses.first?.similarityClusterID == "c1")
    }

    @Test("Same seed yields identical Elo (deterministic)")
    func determinism() async {
        let a = await smallEngine(model: ScriptedModel(), seed: 7).run(researchGoal: "g")
        let b = await smallEngine(model: ScriptedModel(), seed: 7).run(researchGoal: "g")
        #expect(a.topRankedHypotheses.first?.eloRating == b.topRankedHypotheses.first?.eloRating)
    }

    @Test("Degrades gracefully: records errors, never crashes, returns a result")
    func gracefulFailure() async {
        let result = await smallEngine(model: BrokenModel()).run(researchGoal: "g")
        #expect(!result.errors.isEmpty)                          // generation could not parse
        #expect(result.topRankedHypotheses.isEmpty)             // no hypotheses, but no crash
    }

    @Test("Folds decode telemetry into the result (clean run → zero repairs/failures)")
    func telemetryClean() async {
        let metrics = DecodeMetrics()
        let engine = CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: ScriptedModel(), metrics: metrics),
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2, tournamentSize: 2, evolutionTopK: 1),
            seed: 3, decodeMetrics: metrics)
        let result = await engine.run(researchGoal: "g")
        #expect(result.metrics.repairAttempts == 0)
        #expect(result.metrics.decodeFailures == 0)
    }

    @Test("Folds decode failures when the model can't produce valid JSON")
    func telemetryFailures() async {
        let metrics = DecodeMetrics()
        let engine = CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: BrokenModel(), metrics: metrics),
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2, tournamentSize: 2, evolutionTopK: 1),
            seed: 3, decodeMetrics: metrics)
        let result = await engine.run(researchGoal: "g")
        #expect(result.metrics.decodeFailures > 0)
    }
}
