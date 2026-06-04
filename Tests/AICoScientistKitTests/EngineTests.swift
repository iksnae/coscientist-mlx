import Foundation
import Testing
@testable import AICoScientistKit

/// Thread-safe sink for progress events (the engine invokes the handler serially, but this
/// keeps Sendability honest).
private final class ProgressCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [WorkflowProgress] = []
    func add(_ event: WorkflowProgress) { lock.lock(); stored.append(event); lock.unlock() }
    var events: [WorkflowProgress] { lock.lock(); defer { lock.unlock() }; return stored }
}

/// A mock model that answers each agent according to its system prompt, enabling a full,
/// deterministic engine run with no MLX and no downloads.
private struct ScriptedModel: LanguageModel {
    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String {
        if system.contains("Hypothesis Generation Agent") {
            return #"{"hypotheses":[{"text":"Hypothesis Alpha","justification":"j"},{"text":"Hypothesis Beta","justification":"j"}]}"#
        }
        if system.contains("Hypothesis Reflection Agent") {
            return #"{"scores":{"scientificSoundness":0.8,"novelty":0.7,"relevance":0.75,"testability":0.9,"clarity":0.8,"impact":0.6},"reviewSummary":"solid","safetyEthicalConcerns":"None identified","strengths":["s"],"weaknesses":["w"],"suggestions":["fix"]}"#
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

/// Counts how many decodes flow through it — used to prove per-role routing.
private actor CallCounter {
    private(set) var count = 0
    func bump() { count += 1 }
}

private struct CountingDecoder: SchemaConstrainedDecoding {
    let inner: SchemaConstrainedDecoder
    let counter: CallCounter
    func decode<T>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T where T: Decodable & Sendable & Schematized {
        await counter.bump()
        return try await inner.decode(type, system: system, user: user, config: config)
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

    @Test("Routes each role to its decoder (tournament → override, rest → default)")
    func perRoleRouting() async {
        let tournamentCounter = CallCounter()
        let defaultCounter = CallCounter()
        let router = RoleDecoderRouter(
            default: CountingDecoder(
                inner: SchemaConstrainedDecoder(model: ScriptedModel()), counter: defaultCounter),
            overrides: [
                .tournament: CountingDecoder(
                    inner: SchemaConstrainedDecoder(model: ScriptedModel()), counter: tournamentCounter)
            ])
        let engine = CoScientistEngine(
            router: router,
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2, tournamentSize: 2, evolutionTopK: 1),
            seed: 9)
        _ = await engine.run(researchGoal: "g")

        // Initial tournament: 2 hypotheses × 3 rounds = 6 (post-evolution pool of 1 skips).
        #expect(await tournamentCounter.count == 6)
        // gen 1 + reflection 2 + meta 1 + evolution 1 + reflection 1 + proximity 1 = 7.
        #expect(await defaultCounter.count == 7)
    }

    @Test("Emits granular progress: phases, per-review, and per-tournament-match")
    func progressEvents() async {
        let collector = ProgressCollector()
        _ = await smallEngine(model: ScriptedModel()).run(researchGoal: "g") { collector.add($0) }
        let events = collector.events

        #expect(events.first?.phase == "generation")
        #expect(events.contains { $0.phase == "proximity" })
        #expect(events.contains { $0.iteration == 1 })   // refinement round reported

        // Per-review sub-steps with detail + countable totals.
        let reviews = events.filter { $0.phase == "reflection" && $0.detail.hasPrefix("review") }
        #expect(reviews.contains { $0.detail.contains("review 1/2") })
        #expect(reviews.contains { $0.fractionCompleted == 0.5 })

        // Per-match sub-steps: 2 hypotheses × 3 rounds = 6, each with a winner in the detail.
        let matches = events.filter { $0.phase == "tournament" && $0.detail.hasPrefix("match") }
        #expect(matches.count == 6)
        #expect(matches.contains { $0.total == 6 })
        #expect(matches.contains { $0.detail.contains("wins") })
    }

    @Test("Records per-phase timing for every phase")
    func perPhaseTiming() async {
        let result = await smallEngine(model: ScriptedModel()).run(researchGoal: "g")
        let keys = Set(result.metrics.agentExecutionTimes.keys)
        #expect(keys.isSuperset(of: [
            "generation", "reflection", "ranking", "tournament",
            "metaReview", "evolution", "proximity", "total",
        ]))
    }

    @Test("Folds the transcript into the result when provided")
    func transcriptFolded() async {
        let transcript = Transcript()
        let engine = CoScientistEngine(
            decoder: SchemaConstrainedDecoder(model: ScriptedModel(), transcript: transcript),
            config: .init(maxIterations: 1, hypothesesPerGeneration: 2, tournamentSize: 2, evolutionTopK: 1),
            seed: 5, transcript: transcript)
        let result = await engine.run(researchGoal: "g")
        #expect(!result.transcript.isEmpty)
        #expect(result.transcript.contains { $0.system.contains("Generation Agent") })
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
