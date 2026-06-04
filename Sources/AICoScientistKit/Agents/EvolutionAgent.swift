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

/// One specific refinement made to a hypothesis (mirrors the reference's `specific_refinements`).
public struct Refinement: Codable, Sendable, Equatable {
    public var aspect: String
    public var change: String
    public var justification: String

    public init(aspect: String, change: String, justification: String) {
        self.aspect = aspect
        self.change = change
        self.justification = justification
    }
}

public struct EvolvedHypothesis: Codable, Sendable, Equatable, Schematized {
    public var originalText: String
    public var refinedText: String
    public var refinementSummary: String
    public var specificRefinements: [Refinement]

    public init(
        originalText: String,
        refinedText: String,
        refinementSummary: String,
        specificRefinements: [Refinement] = []
    ) {
        self.originalText = originalText
        self.refinedText = refinedText
        self.refinementSummary = refinementSummary
        self.specificRefinements = specificRefinements
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        originalText = try c.decode(String.self, forKey: .originalText)
        refinedText = try c.decode(String.self, forKey: .refinedText)
        refinementSummary = try c.decode(String.self, forKey: .refinementSummary)
        specificRefinements =
            try c.decodeIfPresent([Refinement].self, forKey: .specificRefinements) ?? []
    }

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "originalText": .string(),
                "refinedText": .string(),
                "refinementSummary": .string(),
                "specificRefinements": .array(
                    items: .object(
                        properties: [
                            "aspect": .string(),
                            "change": .string(),
                            "justification": .string(),
                        ],
                        required: ["aspect", "change", "justification"]
                    )
                ),
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
