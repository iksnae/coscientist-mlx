/// Input for ranking: the candidate hypothesis texts (optionally pre-scored upstream).
public struct RankingInput: Sendable {
    public let hypotheses: [String]
    public init(hypotheses: [String]) {
        self.hypotheses = hypotheses
    }
}

public struct RankedHypothesis: Codable, Sendable, Equatable {
    public let text: String
    public let overallScore: Double
    public let rankingExplanation: String
}

public struct RankedHypotheses: Codable, Sendable, Equatable, Schematized {
    public let ranked: [RankedHypothesis]

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "ranked": .array(
                    items: .object(
                        properties: [
                            "text": .string(),
                            "overallScore": .number,
                            "rankingExplanation": .string(),
                        ],
                        required: ["text", "overallScore", "rankingExplanation"]
                    )
                )
            ],
            required: ["ranked"]
        )
    }
}

/// Ranks hypotheses from highest to lowest quality with a composite score. Ported from the
/// Python ranking agent prompt.
public struct RankingAgent: Agent {
    public init() {}
    public let name = "HypothesisRanker"

    public let systemPrompt = """
        You are a Hypothesis Ranking Agent. Rank a set of hypotheses from highest to lowest \
        quality based on scientific merit, potential impact, novelty, testability, and \
        feasibility.

        Compute a composite score (0.0–1.0) for each that synthesizes these factors. Prefer \
        consistently strong hypotheses over those with extreme highs and serious lows. \
        Return the hypotheses ordered from highest to lowest with a brief explanation for \
        each ranking decision.
        """

    public func userPrompt(for input: RankingInput) -> String {
        let listing = input.hypotheses.enumerated()
            .map { "\($0 + 1). \($1)" }
            .joined(separator: "\n")
        return """
            Rank the following hypotheses:

            \(listing)
            """
    }

    public typealias Output = RankedHypotheses
}
