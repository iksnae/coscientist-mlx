/// Input for peer review of a single hypothesis.
public struct ReflectionInput: Sendable {
    public let researchGoal: String
    public let hypothesisText: String
    public init(researchGoal: String, hypothesisText: String) {
        self.researchGoal = researchGoal
        self.hypothesisText = hypothesisText
    }
}

/// Peer-reviews a hypothesis, scoring it across the rubric. Output is the shared
/// `HypothesisReview` (Schematized in M2). Ported from the Python reflection agent prompt;
/// scores use the 0.0–1.0 convention to match `ReviewScores`.
public struct ReflectionAgent: Agent {
    public init() {}
    public let name = "HypothesisReflector"

    public let systemPrompt = """
        You are a Hypothesis Reflection Agent acting as a scientific peer reviewer. Review \
        and critique a hypothesis for correctness, novelty, quality, and any safety/ethical \
        concerns.

        Score each dimension from 0.0 to 1.0:
        - scientificSoundness: plausible and consistent with existing knowledge
        - novelty: proposes something new or original
        - testability: can be tested or investigated with scientific methods
        - impact: potential scientific or practical impact if validated

        Scoring guide: 0.0–0.2 poor, 0.2–0.4 fair, 0.4–0.6 good, 0.6–0.8 very good, \
        0.8–1.0 excellent. Provide a concise review summary plus specific strengths, \
        weaknesses, and suggestions for improvement.
        """

    public func userPrompt(for input: ReflectionInput) -> String {
        """
        Research goal: \(input.researchGoal)

        Hypothesis to review:
        \(input.hypothesisText)
        """
    }

    public typealias Output = HypothesisReview
}
