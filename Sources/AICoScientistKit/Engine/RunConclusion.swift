/// The outcome of a run, stated plainly: the top-ranked hypothesis (the conclusion) plus the
/// meta-review synthesis. A pure projection so the UI can lead with the answer.
public struct RunConclusion: Sendable, Equatable {
    public let topHypothesis: String?
    public let topElo: Int?
    /// The meta-review synthesis; may be empty.
    public let synthesis: String

    public var hasResult: Bool { topHypothesis != nil }
}

extension RunSnapshot {
    /// The run's conclusion: the highest-ranked hypothesis + the meta-review synthesis.
    /// `hypotheses` are stored top-ranked first.
    public var conclusion: RunConclusion {
        let top = hypotheses.first
        return RunConclusion(
            topHypothesis: top?.text, topElo: top?.eloRating, synthesis: metaReviewSummary)
    }
}
