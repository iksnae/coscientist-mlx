import Foundation

/// A persistable snapshot of a research run — enough to save results and to seed a future
/// engine for continued refinement. `Codable` so it serializes with no extra machinery.
public struct RunSnapshot: Codable, Sendable, Equatable {
    public var researchGoal: String
    public var hypotheses: [Hypothesis]
    public var metrics: ExecutionMetrics
    public var clusters: [SimilarityCluster]
    public var metaReviewSummary: String
    /// The run's activity feed (M9). Optional on the wire — legacy snapshots decode to `[]`.
    public var activity: [ActivityEvent]
    /// Errors recorded during the run (agent/decode failures the engine kept going past).
    /// Persisted so a run that produced nothing isn't a silent failure. Optional on the wire.
    public var errors: [String]

    public init(
        researchGoal: String,
        hypotheses: [Hypothesis],
        metrics: ExecutionMetrics,
        clusters: [SimilarityCluster],
        metaReviewSummary: String,
        activity: [ActivityEvent] = [],
        errors: [String] = []
    ) {
        self.researchGoal = researchGoal
        self.hypotheses = hypotheses
        self.metrics = metrics
        self.clusters = clusters
        self.metaReviewSummary = metaReviewSummary
        self.activity = activity
        self.errors = errors
    }

    /// Build a snapshot from a completed workflow result.
    public init(researchGoal: String, result: WorkflowResult) {
        self.init(
            researchGoal: researchGoal,
            hypotheses: result.topRankedHypotheses,
            metrics: result.metrics,
            clusters: result.clusters,
            metaReviewSummary: result.metaReviewSummary,
            errors: result.errors
        )
    }

    private enum CodingKeys: String, CodingKey {
        case researchGoal, hypotheses, metrics, clusters, metaReviewSummary, activity, errors
    }

    /// Decode tolerantly: `activity`/`errors` were added later, so older snapshots omit them.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        researchGoal = try c.decode(String.self, forKey: .researchGoal)
        hypotheses = try c.decode([Hypothesis].self, forKey: .hypotheses)
        metrics = try c.decode(ExecutionMetrics.self, forKey: .metrics)
        clusters = try c.decode([SimilarityCluster].self, forKey: .clusters)
        metaReviewSummary = try c.decode(String.self, forKey: .metaReviewSummary)
        activity = try c.decodeIfPresent([ActivityEvent].self, forKey: .activity) ?? []
        errors = try c.decodeIfPresent([String].self, forKey: .errors) ?? []
    }

    /// A human-readable Markdown report of the run (for sharing / export).
    public func markdown() -> String {
        var lines: [String] = ["# AI Co-Scientist — \(researchGoal)", ""]

        lines.append("## Top hypotheses")
        if hypotheses.isEmpty {
            lines.append("_None._")
        } else {
            for (rank, h) in hypotheses.enumerated() {
                lines.append(
                    "\(rank + 1). **[Elo \(h.eloRating) · score \(String(format: "%.2f", h.score))]** "
                    + h.text)
                var meta: [String] = []
                if let cluster = h.similarityClusterID { meta.append("cluster `\(cluster)`") }
                if h.totalMatches > 0 {
                    meta.append("win rate \(Int(h.winRate))% (\(h.totalMatches) matches)")
                }
                if !meta.isEmpty { lines.append("   - " + meta.joined(separator: " · ")) }
            }
        }

        if !metaReviewSummary.isEmpty {
            lines.append(contentsOf: ["", "## Meta-review", metaReviewSummary])
        }

        if !clusters.isEmpty {
            lines.append(contentsOf: ["", "## Clusters"])
            for c in clusters {
                lines.append("- `\(c.clusterID)` — \(c.memberIDs.count) hypotheses")
            }
        }

        lines.append(contentsOf: [
            "", "## Metrics",
            "- hypotheses: \(metrics.hypothesisCount)",
            "- reviews: \(metrics.reviewsCount)",
            "- tournament matches: \(metrics.tournamentsCount)",
            "- evolutions: \(metrics.evolutionsCount)",
            "- repair retries: \(metrics.repairAttempts)",
            "- decode failures: \(metrics.decodeFailures)",
        ])
        return lines.joined(separator: "\n") + "\n"
    }

    /// CSV of the ranked hypotheses (rank, elo, score, win rate, cluster, text) for spreadsheets.
    public func csv() -> String {
        var rows = ["rank,elo,score,winRate,cluster,text"]
        for (index, h) in hypotheses.enumerated() {
            let cells = [
                String(index + 1),
                String(h.eloRating),
                String(format: "%.4f", h.score),
                String(format: "%.1f", h.winRate),
                h.similarityClusterID ?? "",
                h.text,
            ]
            rows.append(cells.map(Self.csvEscape).joined(separator: ","))
        }
        return rows.joined(separator: "\n") + "\n"
    }

    static func csvEscape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
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
