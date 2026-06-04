import Foundation

/// A read-only projection of a `Hypothesis` for the results inspector. Pure — derives the
/// display sections from the stored hypothesis so the SwiftUI inspector stays a thin renderer
/// and the logic is unit-testable without any UI.
public struct HypothesisDetail: Sendable, Equatable, Identifiable {
    public let id: UUID
    public let text: String
    public let eloRating: Int
    public let score: Double
    public let winCount: Int
    public let lossCount: Int
    public let totalMatches: Int
    public let winRate: Double
    public let clusterID: String?
    /// Evolution lineage, oldest → newest (`Hypothesis.evolutionHistory`).
    public let lineage: [String]
    public let reviewCount: Int
    /// The most recent peer review (six dimensions + qualitative feedback), if any.
    public let latestReview: HypothesisReview?

    public init(_ hypothesis: Hypothesis) {
        id = hypothesis.id
        text = hypothesis.text
        eloRating = hypothesis.eloRating
        score = hypothesis.score
        winCount = hypothesis.winCount
        lossCount = hypothesis.lossCount
        totalMatches = hypothesis.totalMatches
        winRate = hypothesis.winRate
        clusterID = hypothesis.similarityClusterID
        lineage = hypothesis.evolutionHistory
        reviewCount = hypothesis.reviews.count
        latestReview = hypothesis.reviews.last
    }
}

/// The result of selecting a node in the results graph. The graph's node-id scheme (see
/// `GraphView`) is: a hypothesis UUID string, `cluster:<clusterID>`, or a pipeline phase id.
public enum GraphSelection: Sendable, Equatable {
    case hypothesis(HypothesisDetail)
    case cluster(id: String, memberCount: Int)
    case operation(phase: String)

    /// Resolve a tapped node id against the run's hypotheses. Returns nil for an
    /// unrecognized id. Pure — the same resolver backs both the graph tap and tests.
    public static func resolve(nodeID: String, in hypotheses: [Hypothesis]) -> GraphSelection? {
        let clusterPrefix = "cluster:"
        if nodeID.hasPrefix(clusterPrefix) {
            let cid = String(nodeID.dropFirst(clusterPrefix.count))
            let members = hypotheses.filter { $0.similarityClusterID == cid }.count
            return .cluster(id: cid, memberCount: members)
        }
        if let uuid = UUID(uuidString: nodeID),
            let match = hypotheses.first(where: { $0.id == uuid }) {
            return .hypothesis(HypothesisDetail(match))
        }
        if AgentRole(rawValue: nodeID) != nil {
            return .operation(phase: nodeID)
        }
        return nil
    }
}
