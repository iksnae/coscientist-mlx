/// One row in the transparent activity feed — a typed, persistable record of a single
/// pipeline step, derived from a `WorkflowProgress` snapshot. Pure and `Codable` so the feed
/// survives the run on `RunSnapshot` and renders without any live state.
public struct ActivityEvent: Codable, Sendable, Equatable, Identifiable {
    /// Phase family, used for the per-row icon.
    public enum Kind: String, Codable, Sendable, CaseIterable {
        case generation, reflection, ranking, tournament, metaReview, evolution, proximity
        case tool, other

        /// Map a `WorkflowProgress.phase` string to a kind; unknown phases → `.other`.
        public init(phase: String) { self = Kind(rawValue: phase) ?? .other }
    }

    public let step: Int
    public let phase: String
    public let kind: Kind
    public let iteration: Int
    public let detail: String
    public let completed: Int
    public let total: Int
    /// Highest Elo in the pool at this step, if any hypotheses exist yet.
    public let topElo: Int?
    /// Pool size at this step, if any hypotheses exist yet.
    public let poolSize: Int?

    public var id: Int { step }

    public init(
        step: Int, phase: String, kind: Kind, iteration: Int, detail: String,
        completed: Int, total: Int, topElo: Int?, poolSize: Int?
    ) {
        self.step = step
        self.phase = phase
        self.kind = kind
        self.iteration = iteration
        self.detail = detail
        self.completed = completed
        self.total = total
        self.topElo = topElo
        self.poolSize = poolSize
    }

    /// Build an event from a single progress snapshot at `step`.
    public init(step: Int, progress: WorkflowProgress) {
        let elos = progress.hypotheses.map(\.eloRating)
        self.init(
            step: step, phase: progress.phase, kind: Kind(phase: progress.phase),
            iteration: progress.iteration, detail: progress.detail,
            completed: progress.completed, total: progress.total,
            topElo: elos.max(), poolSize: elos.isEmpty ? nil : elos.count)
    }

    /// Derive a typed feed from an ordered sequence of progress snapshots.
    public static func feed(from progress: [WorkflowProgress]) -> [ActivityEvent] {
        progress.enumerated().map { ActivityEvent(step: $0.offset, progress: $0.element) }
    }
}
