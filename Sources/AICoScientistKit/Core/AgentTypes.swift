import Foundation

/// Structured outputs exchanged between agents. Every agent returns one of these
/// typed values; in M2 the language model is constrained to emit JSON that decodes
/// directly into them (replacing the reference's best-effort `_safely_parse_json`).

/// Per-dimension review scores (0.0–1.0), mirroring the reference's six criteria.
public struct ReviewScores: Codable, Sendable, Equatable {
    public var scientificSoundness: Double
    public var novelty: Double
    public var relevance: Double
    public var testability: Double
    public var clarity: Double
    public var impact: Double

    public init(
        scientificSoundness: Double,
        novelty: Double,
        relevance: Double,
        testability: Double,
        clarity: Double,
        impact: Double
    ) {
        self.scientificSoundness = scientificSoundness
        self.novelty = novelty
        self.relevance = relevance
        self.testability = testability
        self.clarity = clarity
        self.impact = impact
    }

    /// Mean across the six dimensions — the overall hypothesis score.
    public var overall: Double {
        (scientificSoundness + novelty + relevance + testability + clarity + impact) / 6.0
    }
}

/// A single peer review produced by the reflection agent. Mirrors the reference's review:
/// six-criterion scores, a summary, qualitative feedback, and a safety/ethical assessment.
public struct HypothesisReview: Codable, Sendable, Equatable {
    public var scores: ReviewScores
    public var reviewSummary: String
    public var safetyEthicalConcerns: String
    public var strengths: [String]
    public var weaknesses: [String]
    public var suggestions: [String]

    public init(
        scores: ReviewScores,
        reviewSummary: String,
        safetyEthicalConcerns: String = "None identified",
        strengths: [String] = [],
        weaknesses: [String] = [],
        suggestions: [String] = []
    ) {
        self.scores = scores
        self.reviewSummary = reviewSummary
        self.safetyEthicalConcerns = safetyEthicalConcerns
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.suggestions = suggestions
    }

    // Lenient decoding: a model may omit qualitative lists or the safety field even when
    // the schema requests them; default rather than fail (the schema decoder still nudges
    // for them on the first pass).
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        scores = try c.decode(ReviewScores.self, forKey: .scores)
        reviewSummary = try c.decode(String.self, forKey: .reviewSummary)
        safetyEthicalConcerns =
            try c.decodeIfPresent(String.self, forKey: .safetyEthicalConcerns) ?? "None identified"
        strengths = try c.decodeIfPresent([String].self, forKey: .strengths) ?? []
        weaknesses = try c.decodeIfPresent([String].self, forKey: .weaknesses) ?? []
        suggestions = try c.decodeIfPresent([String].self, forKey: .suggestions) ?? []
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
public struct ExecutionMetrics: Codable, Sendable, Equatable {
    public var hypothesisCount: Int
    public var reviewsCount: Int
    public var tournamentsCount: Int
    public var evolutionsCount: Int
    /// Total repair retries across all structured decodes (how often models needed a 2nd try).
    public var repairAttempts: Int
    /// Decodes that never produced a valid value after all retries.
    public var decodeFailures: Int
    public var agentExecutionTimes: [String: TimeInterval]

    public init(
        hypothesisCount: Int = 0,
        reviewsCount: Int = 0,
        tournamentsCount: Int = 0,
        evolutionsCount: Int = 0,
        repairAttempts: Int = 0,
        decodeFailures: Int = 0,
        agentExecutionTimes: [String: TimeInterval] = [:]
    ) {
        self.hypothesisCount = hypothesisCount
        self.reviewsCount = reviewsCount
        self.tournamentsCount = tournamentsCount
        self.evolutionsCount = evolutionsCount
        self.repairAttempts = repairAttempts
        self.decodeFailures = decodeFailures
        self.agentExecutionTimes = agentExecutionTimes
    }
}
