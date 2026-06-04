import Foundation

/// A persistable snapshot of a research run — enough to save results and to seed a future
/// engine for continued refinement. `Codable` so it serializes with no extra machinery.
public struct RunSnapshot: Codable, Sendable, Equatable {
    public var researchGoal: String
    public var hypotheses: [Hypothesis]
    public var metrics: ExecutionMetrics
    public var clusters: [SimilarityCluster]
    public var metaReviewSummary: String

    public init(
        researchGoal: String,
        hypotheses: [Hypothesis],
        metrics: ExecutionMetrics,
        clusters: [SimilarityCluster],
        metaReviewSummary: String
    ) {
        self.researchGoal = researchGoal
        self.hypotheses = hypotheses
        self.metrics = metrics
        self.clusters = clusters
        self.metaReviewSummary = metaReviewSummary
    }

    /// Build a snapshot from a completed workflow result.
    public init(researchGoal: String, result: WorkflowResult) {
        self.init(
            researchGoal: researchGoal,
            hypotheses: result.topRankedHypotheses,
            metrics: result.metrics,
            clusters: result.clusters,
            metaReviewSummary: result.metaReviewSummary
        )
    }
}

/// Reads/writes `RunSnapshot`s as pretty, stable JSON. Replaces the reference's per-agent
/// state blobs with a single typed snapshot.
public enum RunStore {
    public static func save(_ snapshot: RunSnapshot, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(snapshot).write(to: url, options: .atomic)
    }

    public static func load(from url: URL) throws -> RunSnapshot {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(RunSnapshot.self, from: data)
    }
}
