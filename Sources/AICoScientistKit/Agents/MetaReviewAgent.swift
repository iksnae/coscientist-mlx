/// Input for meta-review: a digest of all hypothesis reviews from this round.
public struct MetaReviewInput: Sendable {
    public let reviewsDigest: String
    public init(reviewsDigest: String) {
        self.reviewsDigest = reviewsDigest
    }
}

public struct MetaReview: Codable, Sendable, Equatable, Schematized {
    public let metaReviewSummary: String
    public let strengths: [String]
    public let weaknesses: [String]
    public let strategicRecommendations: [String]

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "metaReviewSummary": .string(),
                "strengths": .array(items: .string()),
                "weaknesses": .array(items: .string()),
                "strategicRecommendations": .array(items: .string()),
            ],
            required: ["metaReviewSummary"]
        )
    }
}

/// Synthesizes insights across all reviews into strategic guidance for evolution. Ported
/// from the Python meta-review agent prompt; the deeply nested example is flattened to the
/// fields the engine consumes.
public struct MetaReviewAgent: Agent {
    public init() {}
    public let name = "MetaReviewer"

    public let systemPrompt = """
        You are a Meta-Review Agent. Synthesize insights across all hypothesis reviews.

        Identify recurring strengths and weaknesses across hypotheses, assess the overall \
        research direction's alignment with the goal, and provide high-level strategic \
        recommendations the evolution agent should focus on. Return a concise overall \
        summary, common strengths, common weaknesses, and strategic recommendations.
        """

    public func userPrompt(for input: MetaReviewInput) -> String {
        """
        Reviews to synthesize:

        \(input.reviewsDigest)
        """
    }

    public typealias Output = MetaReview
}
