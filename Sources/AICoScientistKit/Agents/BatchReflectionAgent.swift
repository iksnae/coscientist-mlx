/// Input for reviewing a whole pool of hypotheses in one pass.
public struct BatchReflectionInput: Sendable {
    public let researchGoal: String
    /// Hypothesis texts, in order; reviews come back aligned to this order.
    public let hypotheses: [String]
    public init(researchGoal: String, hypotheses: [String]) {
        self.researchGoal = researchGoal
        self.hypotheses = hypotheses
    }
}

/// A batch of peer reviews, one per input hypothesis (positionally aligned).
public struct BatchReviews: Codable, Sendable, Equatable, Schematized {
    public let reviews: [HypothesisReview]
    public init(reviews: [HypothesisReview]) { self.reviews = reviews }

    public static var jsonSchema: JSONSchema {
        .object(
            properties: ["reviews": .array(items: HypothesisReview.jsonSchema)],
            required: ["reviews"]
        )
    }
}

/// Peer-reviews an entire hypothesis pool in a single structured call — the batched form of
/// `ReflectionAgent`, cutting the reflection phase from O(N) decodes to one. Same rubric; the
/// output is one `HypothesisReview` per hypothesis, in input order.
public struct BatchReflectionAgent: Agent {
    public init() {}
    public let name = "BatchHypothesisReflector"

    public let systemPrompt = """
        You are a Hypothesis Reflection Agent acting as a scientific peer reviewer. Review and \
        critique EACH hypothesis in the provided list for correctness, novelty, quality, and \
        any safety/ethical concerns.

        Score each dimension from 0.0 to 1.0:
        - scientificSoundness: plausible and consistent with existing knowledge
        - novelty: proposes something new or original
        - relevance: addresses the stated research goal
        - testability: can be tested or investigated with scientific methods
        - clarity: clearly and precisely stated
        - impact: potential scientific or practical impact if validated

        Scoring guide: 0.0–0.2 poor, 0.2–0.4 fair, 0.4–0.6 good, 0.6–0.8 very good, \
        0.8–1.0 excellent. Also state any safety or ethical concerns (or "None identified"), \
        plus a concise summary and specific strengths, weaknesses, and suggestions.

        Return one review per hypothesis, in the SAME ORDER as the list, in the "reviews" array.
        """

    public func userPrompt(for input: BatchReflectionInput) -> String {
        let list = input.hypotheses.enumerated()
            .map { "\($0.offset + 1). \($0.element)" }
            .joined(separator: "\n\n")
        return """
            Research goal: \(input.researchGoal)

            Review each of the following \(input.hypotheses.count) hypotheses. Return a "reviews" \
            array with exactly one entry per hypothesis, in the same order:

            \(list)
            """
    }

    public typealias Output = BatchReviews
}
