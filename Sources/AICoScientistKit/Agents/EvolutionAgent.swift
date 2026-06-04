/// Input for evolving a single top-ranked hypothesis.
public struct EvolutionInput: Sendable {
    public let originalText: String
    public let reviewFeedback: String
    public let metaReviewInsights: String
    public init(originalText: String, reviewFeedback: String, metaReviewInsights: String) {
        self.originalText = originalText
        self.reviewFeedback = reviewFeedback
        self.metaReviewInsights = metaReviewInsights
    }
}

public struct EvolvedHypothesis: Codable, Sendable, Equatable, Schematized {
    public let originalText: String
    public let refinedText: String
    public let refinementSummary: String

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "originalText": .string(),
                "refinedText": .string(),
                "refinementSummary": .string(),
            ],
            required: ["originalText", "refinedText", "refinementSummary"]
        )
    }
}

/// Refines a hypothesis using review feedback and meta-review insights. Ported from the
/// Python evolution agent prompt.
public struct EvolutionAgent: Agent {
    public init() {}
    public let name = "HypothesisEvolver"

    public let systemPrompt = """
        You are a Hypothesis Evolution Agent. Refine and improve a top-ranked hypothesis \
        using its review feedback and meta-review insights.

        Apply, where helpful: clearer and more precise language; stronger scientific \
        soundness; greater novelty; improved testability and falsifiability; integrated \
        safety/ethical considerations; hybridization with complementary ideas; and \
        simplification of unnecessary complexity. Preserve the hypothesis's intent.

        Return the original text, the refined text, and a concise summary of the changes.
        """

    public func userPrompt(for input: EvolutionInput) -> String {
        """
        Original hypothesis:
        \(input.originalText)

        Review feedback:
        \(input.reviewFeedback)

        Meta-review insights:
        \(input.metaReviewInsights)
        """
    }

    public typealias Output = EvolvedHypothesis
}
