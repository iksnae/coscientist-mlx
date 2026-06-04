/// A live snapshot emitted after each workflow phase, for UIs that show the run unfolding.
public struct WorkflowProgress: Sendable {
    /// The phase that just completed (e.g. "generation", "tournament").
    public let phase: String
    /// 0 during the initial pass; 1…n during refinement iterations.
    public let iteration: Int
    /// The current hypothesis pool, sorted by Elo (highest first).
    public let hypotheses: [Hypothesis]
    /// Metrics accumulated so far.
    public let metrics: ExecutionMetrics

    public init(phase: String, iteration: Int, hypotheses: [Hypothesis], metrics: ExecutionMetrics) {
        self.phase = phase
        self.iteration = iteration
        self.hypotheses = hypotheses
        self.metrics = metrics
    }
}
