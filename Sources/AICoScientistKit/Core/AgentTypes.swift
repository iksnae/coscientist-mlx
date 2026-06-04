import Foundation

/// Structured outputs exchanged between agents. Every agent returns one of these
/// typed values; in M2 the language model is constrained to emit JSON that decodes
/// directly into them (replacing the reference's best-effort `_safely_parse_json`).

/// Per-dimension review scores (0.0–1.0), mirroring the reference `ReviewScores`.
public struct ReviewScores: Codable, Sendable, Equatable {
    public var scientificSoundness: Double
    public var novelty: Double
    public var testability: Double
    public var impact: Double

    public init(
        scientificSoundness: Double,
        novelty: Double,
        testability: Double,
        impact: Double
    ) {
        self.scientificSoundness = scientificSoundness
        self.novelty = novelty
        self.testability = testability
        self.impact = impact
    }

    /// Mean across the four dimensions — the overall hypothesis score.
    public var overall: Double {
        (scientificSoundness + novelty + testability + impact) / 4.0
    }
}

/// A single peer review produced by the reflection agent.
public struct HypothesisReview: Codable, Sendable, Equatable {
    public var scores: ReviewScores
    public var reviewSummary: String
    public var strengths: [String]
    public var weaknesses: [String]
    public var suggestions: [String]

    public init(
        scores: ReviewScores,
        reviewSummary: String,
        strengths: [String] = [],
        weaknesses: [String] = [],
        suggestions: [String] = []
    ) {
        self.scores = scores
        self.reviewSummary = reviewSummary
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.suggestions = suggestions
    }
}

/// The tournament judge's verdict for a pairwise match.
public struct TournamentJudgment: Codable, Sendable, Equatable {
    public enum Winner: String, Codable, Sendable {
        case a
        case b
    }

    public var winner: Winner
    public var rationale: String

    public init(winner: Winner, rationale: String) {
        self.winner = winner
        self.rationale = rationale
    }
}

/// One cluster of similar hypotheses from proximity analysis.
public struct SimilarityCluster: Codable, Sendable, Equatable {
    public var clusterID: String
    public var memberIDs: [UUID]

    public init(clusterID: String, memberIDs: [UUID]) {
        self.clusterID = clusterID
        self.memberIDs = memberIDs
    }
}

/// Outcome of a completed research workflow.
public struct WorkflowResult: Codable, Sendable {
    public var topRankedHypotheses: [Hypothesis]
    public var metaReviewSummary: String
    public var clusters: [SimilarityCluster]
    public var metrics: ExecutionMetrics
    public var totalWorkflowTime: TimeInterval
    public var errors: [String]

    public init(
        topRankedHypotheses: [Hypothesis] = [],
        metaReviewSummary: String = "",
        clusters: [SimilarityCluster] = [],
        metrics: ExecutionMetrics = ExecutionMetrics(),
        totalWorkflowTime: TimeInterval = 0,
        errors: [String] = []
    ) {
        self.topRankedHypotheses = topRankedHypotheses
        self.metaReviewSummary = metaReviewSummary
        self.clusters = clusters
        self.metrics = metrics
        self.totalWorkflowTime = totalWorkflowTime
        self.errors = errors
    }
}

/// Per-run execution metrics, mirroring the reference `ExecutionMetrics`.
public struct ExecutionMetrics: Codable, Sendable {
    public var hypothesisCount: Int
    public var reviewsCount: Int
    public var tournamentsCount: Int
    public var evolutionsCount: Int
    public var agentExecutionTimes: [String: TimeInterval]

    public init(
        hypothesisCount: Int = 0,
        reviewsCount: Int = 0,
        tournamentsCount: Int = 0,
        evolutionsCount: Int = 0,
        agentExecutionTimes: [String: TimeInterval] = [:]
    ) {
        self.hypothesisCount = hypothesisCount
        self.reviewsCount = reviewsCount
        self.tournamentsCount = tournamentsCount
        self.evolutionsCount = evolutionsCount
        self.agentExecutionTimes = agentExecutionTimes
    }
}
