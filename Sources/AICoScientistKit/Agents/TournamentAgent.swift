/// Input for a pairwise tournament match.
public struct TournamentInput: Sendable {
    public let researchGoal: String
    public let hypothesisA: String
    public let hypothesisB: String
    public init(researchGoal: String, hypothesisA: String, hypothesisB: String) {
        self.researchGoal = researchGoal
        self.hypothesisA = hypothesisA
        self.hypothesisB = hypothesisB
    }
}

/// Judges which of two hypotheses is superior. Output is the shared `TournamentJudgment`
/// (Schematized in M2). Ported from the Python tournament agent prompt.
public struct TournamentAgent: Agent {
    public init() {}
    public let name = "TournamentJudge"

    public let systemPrompt = """
        You are a Tournament Judge Agent. Given two hypotheses and a research goal, decide \
        which one is superior for addressing the goal.

        Compare them on scientific soundness, novelty, relevance to the goal, testability \
        and falsifiability, clarity, potential impact, and feasibility. Make a clear \
        decision — winner "a" or "b" — and give a concise rationale citing the deciding \
        strengths and weaknesses.
        """

    public func userPrompt(for input: TournamentInput) -> String {
        """
        Research goal: \(input.researchGoal)

        Hypothesis A:
        \(input.hypothesisA)

        Hypothesis B:
        \(input.hypothesisB)
        """
    }

    public typealias Output = TournamentJudgment
}
