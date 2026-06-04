/// A live snapshot emitted during a run, for UIs that show the workflow unfolding. Emitted
/// both at phase boundaries and at sub-steps (each review, each tournament match, each
/// evolution) for fine-grained progress.
public struct WorkflowProgress: Sendable {
    /// The active phase (e.g. "generation", "tournament").
    public let phase: String
    /// 0 during the initial pass; 1…n during refinement iterations.
    public let iteration: Int
    /// Human-readable sub-step, e.g. "review 3/4" or "match 12/18: A wins". May be empty.
    public let detail: String
    /// Units completed within the current phase (0 when not applicable).
    public let completed: Int
    /// Total units in the current phase (0 when not applicable).
    public let total: Int
    /// The current hypothesis pool, sorted by Elo (highest first).
    public let hypotheses: [Hypothesis]
    /// Metrics accumulated so far.
    public let metrics: ExecutionMetrics

    public init(
        phase: String,
        iteration: Int,
        detail: String = "",
        completed: Int = 0,
        total: Int = 0,
        hypotheses: [Hypothesis],
        metrics: ExecutionMetrics
    ) {
        self.phase = phase
        self.iteration = iteration
        self.detail = detail
        self.completed = completed
        self.total = total
        self.hypotheses = hypotheses
        self.metrics = metrics
    }

    /// Progress within the current phase, 0…1, or `nil` when there are no countable units.
    public var fractionCompleted: Double? {
        total > 0 ? Double(completed) / Double(total) : nil
    }
}
