import Foundation

/// A research hypothesis tracked through the co-scientist workflow.
///
/// Mirrors the Python `Hypothesis` dataclass but uses a stable `id` so that
/// downstream phases (proximity clustering, evolution lineage) never rely on
/// fragile text equality, which the reference implementation does.
public struct Hypothesis: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var text: String
    public var eloRating: Int
    public var reviews: [HypothesisReview]
    public var score: Double
    public var similarityClusterID: String?
    public var evolutionHistory: [String]
    public var winCount: Int
    public var lossCount: Int

    public init(
        id: UUID = UUID(),
        text: String,
        eloRating: Int = 1200,
        reviews: [HypothesisReview] = [],
        score: Double = 0.0,
        similarityClusterID: String? = nil,
        evolutionHistory: [String] = [],
        winCount: Int = 0,
        lossCount: Int = 0
    ) {
        self.id = id
        self.text = text
        self.eloRating = eloRating
        self.reviews = reviews
        self.score = score
        self.similarityClusterID = similarityClusterID
        self.evolutionHistory = evolutionHistory
        self.winCount = winCount
        self.lossCount = lossCount
    }

    public var totalMatches: Int { winCount + lossCount }

    public var winRate: Double {
        guard totalMatches > 0 else { return 0 }
        return (Double(winCount) / Double(totalMatches) * 100).rounded(toPlaces: 2)
    }

    /// Update this hypothesis's Elo rating after a tournament match.
    ///
    /// Standard Elo: expected score from the rating gap, then move by
    /// `kFactor * (actual - expected)`. Matches the reference's integer rounding.
    public mutating func updateElo(opponentElo: Int, didWin: Bool, kFactor: Int = 32) {
        let expected = 1.0 / (1.0 + pow(10.0, Double(opponentElo - eloRating) / 400.0))
        let actual = didWin ? 1.0 : 0.0
        eloRating += Int((Double(kFactor) * (actual - expected)).rounded(.towardZero))
        if didWin { winCount += 1 } else { lossCount += 1 }
    }
}

extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
