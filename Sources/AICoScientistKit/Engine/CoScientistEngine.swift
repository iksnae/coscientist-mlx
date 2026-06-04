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
    private let router: any DecoderRouting
    private let proximityAnalyzer: any ProximityAnalyzer
    private let config: EngineConfiguration
    private let decodeMetrics: DecodeMetrics?
    private let transcript: Transcript?
    private var rng: SeededGenerator

    private var hypotheses: [Hypothesis] = []
    private var metrics = ExecutionMetrics()
    private var clusters: [SimilarityCluster] = []
    private var errors: [String] = []
    private var iteration = 0
    private var onProgress: (@Sendable (WorkflowProgress) -> Void)?

    /// - Parameter proximityAnalyzer: clustering strategy. Defaults to the LLM agent path;
    ///   pass an `EmbeddingProximityAnalyzer` for the embedding-based (preferred) path.
    /// Designated initializer: route each agent role to a (possibly different) decoder.
    /// - Parameter decodeMetrics: pass the same `DecodeMetrics` you gave the decoders to fold
    ///   repair/failure telemetry into the result.
    public init(
        router: any DecoderRouting,
        config: EngineConfiguration = .init(),
        seed: UInt64? = nil,
        proximityAnalyzer: (any ProximityAnalyzer)? = nil,
        decodeMetrics: DecodeMetrics? = nil,
        transcript: Transcript? = nil
    ) {
        self.router = router
        self.proximityAnalyzer =
            proximityAnalyzer ?? AgentProximityAnalyzer(decoder: router.decoder(for: .proximity))
        self.config = config
        self.decodeMetrics = decodeMetrics
        self.transcript = transcript
        self.rng = SeededGenerator(seed: seed ?? UInt64.random(in: .min ... .max))
    }

    /// Convenience: use one decoder for every role (backward compatible).
    public init(
        decoder: any SchemaConstrainedDecoding,
        config: EngineConfiguration = .init(),
        seed: UInt64? = nil,
        proximityAnalyzer: (any ProximityAnalyzer)? = nil,
        decodeMetrics: DecodeMetrics? = nil,
        transcript: Transcript? = nil
    ) {
        self.init(
            router: StaticDecoderRouter(decoder),
            config: config,
            seed: seed,
            proximityAnalyzer: proximityAnalyzer,
            decodeMetrics: decodeMetrics,
            transcript: transcript
        )
    }

    /// Run the full workflow for a research goal. Always returns a result.
    /// - Parameter onProgress: optional live callback invoked after each phase with a
    ///   snapshot of the current pool + metrics (for UIs that show the workflow unfolding).
    public func run(
        researchGoal goal: String,
        onProgress: (@Sendable (WorkflowProgress) -> Void)? = nil
    ) async -> WorkflowResult {
        let clock = ContinuousClock()
        let start = clock.now
        reset()
        self.onProgress = onProgress

        if !Task.isCancelled { await timed("generation") { await self.generationPhase(goal: goal) } }
        if !Task.isCancelled { await timed("reflection") { await self.reflectionPhase(goal: goal) } }
        if !Task.isCancelled { await timed("ranking") { self.rankingPhase() } }
        if !Task.isCancelled { await timed("tournament") { await self.tournamentPhase(goal: goal) } }

        let metaSummary = await refinementLoop(
            goal: goal, iterations: config.maxIterations, metaSummary: "")
        return await finish(start: start, clock: clock, metaSummary: metaSummary)
    }

    /// Resume refinement from a saved snapshot: seed the pool/metrics and run more iterations
    /// (meta-review → evolution → reflection → ranking → tournament → proximity), skipping the
    /// initial generation. Lets a saved run be continued.
    public func resume(
        from snapshot: RunSnapshot,
        additionalIterations: Int? = nil,
        onProgress: (@Sendable (WorkflowProgress) -> Void)? = nil
    ) async -> WorkflowResult {
        let clock = ContinuousClock()
        let start = clock.now
        reset()
        self.onProgress = onProgress
        hypotheses = snapshot.hypotheses
        metrics = snapshot.metrics
        clusters = snapshot.clusters

        let metaSummary = await refinementLoop(
            goal: snapshot.researchGoal,
            iterations: additionalIterations ?? config.maxIterations,
            metaSummary: snapshot.metaReviewSummary)
        return await finish(start: start, clock: clock, metaSummary: metaSummary)
    }

    /// The shared refinement loop used by both `run` and `resume`.
    private func refinementLoop(
        goal: String, iterations: Int, metaSummary initial: String
    ) async -> String {
        var metaSummary = initial
        var iter = 0
        while iter < max(0, iterations), !Task.isCancelled {
            iter += 1
            iteration = iter
            var meta: MetaReview?
            await timed("metaReview") { meta = await self.metaReviewPhase() }
            if let meta { metaSummary = meta.metaReviewSummary }
            if Task.isCancelled { break }
            await timed("evolution") { await self.evolutionPhase(meta: meta) }
            await timed("reflection") { await self.reflectionPhase(goal: goal) }
            await timed("ranking") { self.rankingPhase() }
            if Task.isCancelled { break }
            await timed("tournament") { await self.tournamentPhase(goal: goal) }
            await timed("proximity") { await self.proximityPhase() }
        }
        return metaSummary
    }

    /// Build the final result (also used on cancellation, with whatever's been computed).
    private func finish(
        start: ContinuousClock.Instant, clock: ContinuousClock, metaSummary: String
    ) async -> WorkflowResult {
        if Task.isCancelled { errors.append("run cancelled") }
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
                .init(researchGoal: goal, count: config.hypothesesPerGeneration),
                using: router.decoder(for: .generation))
            hypotheses = out.hypotheses.map { Hypothesis(text: $0.text) }
            metrics.hypothesisCount = hypotheses.count
        } catch {
            errors.append("generation: \(error)")
        }
    }

    private func reflectionPhase(goal: String) async {
        let agent = ReflectionAgent()
        let n = hypotheses.count
        for i in hypotheses.indices {
            if Task.isCancelled { break }
            do {
                let review = try await agent.run(
                    .init(researchGoal: goal, hypothesisText: hypotheses[i].text),
                    using: router.decoder(for: .reflection))
                hypotheses[i].reviews.append(review)
                hypotheses[i].score = review.scores.overall
                metrics.reviewsCount += 1
            } catch {
                errors.append("reflection[\(i)]: \(error)")
            }
            report("reflection", "review \(i + 1)/\(n)", completed: i + 1, total: n)
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
        for round in 0..<rounds {
            if Task.isCancelled { break }
            let (i, j) = pickTwoDistinct(in: hypotheses.count)
            var detail = "match \(round + 1)/\(rounds)"
            do {
                let verdict = try await agent.run(
                    .init(researchGoal: goal,
                          hypothesisA: hypotheses[i].text,
                          hypothesisB: hypotheses[j].text),
                    using: router.decoder(for: .tournament))
                let aWon = verdict.winner == .a
                let oldI = hypotheses[i].eloRating
                let oldJ = hypotheses[j].eloRating
                hypotheses[i].updateElo(opponentElo: oldJ, didWin: aWon, kFactor: 24)
                hypotheses[j].updateElo(opponentElo: oldI, didWin: !aWon, kFactor: 24)
                metrics.tournamentsCount += 1
                detail += aWon ? ": A wins" : ": B wins"
            } catch {
                errors.append("tournament: \(error)")
            }
            report("tournament", detail, completed: round + 1, total: rounds)
        }
        hypotheses.sort { $0.eloRating > $1.eloRating }
        report("tournament", "ranked", completed: rounds, total: rounds)
    }

    private func metaReviewPhase() async -> MetaReview? {
        let digest = hypotheses
            .compactMap { h in h.reviews.last.map { "- \(h.text): \($0.reviewSummary)" } }
            .joined(separator: "\n")
        do {
            return try await MetaReviewAgent().run(
                .init(reviewsDigest: digest), using: router.decoder(for: .metaReview))
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
        for (idx, h) in topK.enumerated() {
            let feedback = h.reviews.last.map {
                ($0.weaknesses + $0.suggestions).joined(separator: "; ")
            } ?? ""
            do {
                let out = try await agent.run(
                    .init(originalText: h.text,
                          reviewFeedback: feedback,
                          metaReviewInsights: meta?.metaReviewSummary ?? ""),
                    using: router.decoder(for: .evolution))
                var refined = Hypothesis(text: out.refinedText)
                refined.evolutionHistory = h.evolutionHistory + [h.text]
                evolved.append(refined)
                metrics.evolutionsCount += 1
            } catch {
                errors.append("evolution: \(error)")
                evolved.append(h)  // keep the original on failure
            }
            report("evolution", "evolved \(idx + 1)/\(topK.count)", completed: idx + 1, total: topK.count)
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
        iteration = 0
        onProgress = nil
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
        report(name)
    }

    /// Emit a progress snapshot (phase boundary or sub-step).
    private func report(_ phase: String, _ detail: String = "", completed: Int = 0, total: Int = 0) {
        guard let onProgress else { return }
        onProgress(
            WorkflowProgress(
                phase: phase,
                iteration: iteration,
                detail: detail,
                completed: completed,
                total: total,
                hypotheses: hypotheses.sorted { $0.eloRating > $1.eloRating },
                metrics: metrics))
    }

    private func seconds(since start: ContinuousClock.Instant, clock: ContinuousClock) -> TimeInterval {
        let d = clock.now - start
        return Double(d.components.seconds) + Double(d.components.attoseconds) / 1e18
    }
}
