import Foundation

/// Orchestrates the co-scientist workflow, mirroring the Python `run_research_workflow`:
///
///   generation → reflection → ranking → tournament
///   then for maxIterations: meta-review → evolution(top-k) → reflection → ranking
///                           → tournament → proximity
///
/// An `actor` holding the hypothesis pool and metrics. It depends only on protocols
/// (`SchemaConstrainedDecoding`) — so it runs on the MLX backend in production and on a
/// mock in tests, unchanged. Like the reference, it never throws: per-phase failures are
/// recorded in `WorkflowResult.errors` and the workflow continues.
public actor CoScientistEngine {
    private let decoder: any SchemaConstrainedDecoding
    private let proximityAnalyzer: any ProximityAnalyzer
    private let config: EngineConfiguration
    private let decodeMetrics: DecodeMetrics?
    private let transcript: Transcript?
    private var rng: SeededGenerator

    private var hypotheses: [Hypothesis] = []
    private var metrics = ExecutionMetrics()
    private var clusters: [SimilarityCluster] = []
    private var errors: [String] = []

    /// - Parameter proximityAnalyzer: clustering strategy. Defaults to the LLM agent path;
    ///   pass an `EmbeddingProximityAnalyzer` for the embedding-based (preferred) path.
    /// - Parameter decodeMetrics: pass the same `DecodeMetrics` you gave the decoder to fold
    ///   repair/failure telemetry into the result.
    public init(
        decoder: any SchemaConstrainedDecoding,
        config: EngineConfiguration = .init(),
        seed: UInt64? = nil,
        proximityAnalyzer: (any ProximityAnalyzer)? = nil,
        decodeMetrics: DecodeMetrics? = nil,
        transcript: Transcript? = nil
    ) {
        self.decoder = decoder
        self.proximityAnalyzer = proximityAnalyzer ?? AgentProximityAnalyzer(decoder: decoder)
        self.config = config
        self.decodeMetrics = decodeMetrics
        self.transcript = transcript
        self.rng = SeededGenerator(seed: seed ?? UInt64.random(in: .min ... .max))
    }

    /// Run the full workflow for a research goal. Always returns a result.
    public func run(researchGoal goal: String) async -> WorkflowResult {
        let clock = ContinuousClock()
        let start = clock.now
        reset()

        await timed("generation") { await self.generationPhase(goal: goal) }
        await timed("reflection") { await self.reflectionPhase(goal: goal) }
        await timed("ranking") { self.rankingPhase() }
        await timed("tournament") { await self.tournamentPhase(goal: goal) }

        var metaSummary = ""
        for _ in 0..<max(0, config.maxIterations) {
            var meta: MetaReview?
            await timed("metaReview") { meta = await self.metaReviewPhase() }
            if let meta { metaSummary = meta.metaReviewSummary }
            await timed("evolution") { await self.evolutionPhase(meta: meta) }
            await timed("reflection") { await self.reflectionPhase(goal: goal) }
            await timed("ranking") { self.rankingPhase() }
            await timed("tournament") { await self.tournamentPhase(goal: goal) }
            await timed("proximity") { await self.proximityPhase() }
        }

        if let snapshot = await decodeMetrics?.snapshot() {
            metrics.repairAttempts = snapshot.repairs
            metrics.decodeFailures = snapshot.failures
        }

        let ranked = hypotheses.sorted { $0.eloRating > $1.eloRating }
        metrics.agentExecutionTimes["total"] = seconds(since: start, clock: clock)

        return WorkflowResult(
            topRankedHypotheses: Array(ranked.prefix(10)),
            metaReviewSummary: metaSummary,
            clusters: clusters,
            metrics: metrics,
            totalWorkflowTime: seconds(since: start, clock: clock),
            errors: errors,
            transcript: await transcript?.all() ?? []
        )
    }

    // MARK: - Phases

    private func generationPhase(goal: String) async {
        do {
            let out = try await GenerationAgent().run(
                .init(researchGoal: goal, count: config.hypothesesPerGeneration), using: decoder)
            hypotheses = out.hypotheses.map { Hypothesis(text: $0.text) }
            metrics.hypothesisCount = hypotheses.count
        } catch {
            errors.append("generation: \(error)")
        }
    }

    private func reflectionPhase(goal: String) async {
        let agent = ReflectionAgent()
        for i in hypotheses.indices {
            do {
                let review = try await agent.run(
                    .init(researchGoal: goal, hypothesisText: hypotheses[i].text), using: decoder)
                hypotheses[i].reviews.append(review)
                hypotheses[i].score = review.scores.overall
                metrics.reviewsCount += 1
            } catch {
                errors.append("reflection[\(i)]: \(error)")
            }
        }
    }

    /// Initial ordering by review score (deterministic). Elo from the tournament is the
    /// authoritative final ranking. The `RankingAgent` is available for callers who want
    /// narrative rankings; the engine sorts numerically to avoid fragile text matching.
    private func rankingPhase() {
        hypotheses.sort { $0.score > $1.score }
    }

    private func tournamentPhase(goal: String) async {
        guard hypotheses.count >= 2 else { return }
        let agent = TournamentAgent()
        let rounds = hypotheses.count * 3
        for _ in 0..<rounds {
            let (i, j) = pickTwoDistinct(in: hypotheses.count)
            do {
                let verdict = try await agent.run(
                    .init(researchGoal: goal,
                          hypothesisA: hypotheses[i].text,
                          hypothesisB: hypotheses[j].text),
                    using: decoder)
                let aWon = verdict.winner == .a
                let oldI = hypotheses[i].eloRating
                let oldJ = hypotheses[j].eloRating
                hypotheses[i].updateElo(opponentElo: oldJ, didWin: aWon, kFactor: 24)
                hypotheses[j].updateElo(opponentElo: oldI, didWin: !aWon, kFactor: 24)
                metrics.tournamentsCount += 1
            } catch {
                errors.append("tournament: \(error)")
            }
        }
        hypotheses.sort { $0.eloRating > $1.eloRating }
    }

    private func metaReviewPhase() async -> MetaReview? {
        let digest = hypotheses
            .compactMap { h in h.reviews.last.map { "- \(h.text): \($0.reviewSummary)" } }
            .joined(separator: "\n")
        do {
            return try await MetaReviewAgent().run(.init(reviewsDigest: digest), using: decoder)
        } catch {
            errors.append("meta-review: \(error)")
            return nil
        }
    }

    private func evolutionPhase(meta: MetaReview?) async {
        let topK = Array(hypotheses.prefix(max(0, config.evolutionTopK)))
        guard !topK.isEmpty else { return }
        let agent = EvolutionAgent()
        var evolved: [Hypothesis] = []
        for h in topK {
            let feedback = h.reviews.last.map {
                ($0.weaknesses + $0.suggestions).joined(separator: "; ")
            } ?? ""
            do {
                let out = try await agent.run(
                    .init(originalText: h.text,
                          reviewFeedback: feedback,
                          metaReviewInsights: meta?.metaReviewSummary ?? ""),
                    using: decoder)
                var refined = Hypothesis(text: out.refinedText)
                refined.evolutionHistory = h.evolutionHistory + [h.text]
                evolved.append(refined)
                metrics.evolutionsCount += 1
            } catch {
                errors.append("evolution: \(error)")
                evolved.append(h)  // keep the original on failure
            }
        }
        hypotheses = evolved
    }

    private func proximityPhase() async {
        guard !hypotheses.isEmpty else { return }
        do {
            let result = try await proximityAnalyzer.cluster(hypotheses)
            clusters = result
            var assignment: [UUID: String] = [:]
            for cluster in result {
                for id in cluster.memberIDs { assignment[id] = cluster.clusterID }
            }
            for i in hypotheses.indices {
                hypotheses[i].similarityClusterID = assignment[hypotheses[i].id]
            }
        } catch {
            errors.append("proximity: \(error)")
        }
    }

    // MARK: - Helpers

    private func reset() {
        hypotheses = []
        metrics = ExecutionMetrics()
        clusters = []
        errors = []
    }

    private func pickTwoDistinct(in count: Int) -> (Int, Int) {
        let i = Int.random(in: 0..<count, using: &rng)
        var j = Int.random(in: 0..<count, using: &rng)
        while j == i { j = Int.random(in: 0..<count, using: &rng) }
        return (i, j)
    }

    /// Run a phase, accumulating its wall-clock time under `name` (phases repeat across
    /// iterations, so times sum) — mirroring the reference's per-agent timing.
    private func timed(_ name: String, _ body: () async -> Void) async {
        let clock = ContinuousClock()
        let start = clock.now
        await body()
        metrics.agentExecutionTimes[name, default: 0] += seconds(since: start, clock: clock)
    }

    private func seconds(since start: ContinuousClock.Instant, clock: ContinuousClock) -> TimeInterval {
        let d = clock.now - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }
}
