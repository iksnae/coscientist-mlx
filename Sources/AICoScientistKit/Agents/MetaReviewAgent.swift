/// Input for meta-review: a digest of all hypothesis reviews from this round.
public struct MetaReviewInput: Sendable {
    public let reviewsDigest: String
    public init(reviewsDigest: String) {
        self.reviewsDigest = reviewsDigest
    }
}

/// How the generation / review / evolution process is performing, per the meta-reviewer.
public struct ProcessAssessment: Codable, Sendable, Equatable {
    public var generation: String
    public var review: String
    public var evolution: String

    public init(generation: String = "", review: String = "", evolution: String = "") {
        self.generation = generation
        self.review = review
        self.evolution = evolution
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        generation = try c.decodeIfPresent(String.self, forKey: .generation) ?? ""
        review = try c.decodeIfPresent(String.self, forKey: .review) ?? ""
        evolution = try c.decodeIfPresent(String.self, forKey: .evolution) ?? ""
    }
}

public struct MetaReview: Codable, Sendable, Equatable, Schematized {
    public var metaReviewSummary: String
    public var recurringThemes: [String]
    public var strengths: [String]
    public var weaknesses: [String]
    public var processAssessment: ProcessAssessment
    public var strategicRecommendations: [String]
    public var potentialConnections: [String]

    public init(
        metaReviewSummary: String,
        recurringThemes: [String] = [],
        strengths: [String] = [],
        weaknesses: [String] = [],
        processAssessment: ProcessAssessment = .init(),
        strategicRecommendations: [String] = [],
        potentialConnections: [String] = []
    ) {
        self.metaReviewSummary = metaReviewSummary
        self.recurringThemes = recurringThemes
        self.strengths = strengths
        self.weaknesses = weaknesses
        self.processAssessment = processAssessment
        self.strategicRecommendations = strategicRecommendations
        self.potentialConnections = potentialConnections
    }

    // Only the summary is mandatory; everything else defaults so a terse model still decodes.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        metaReviewSummary = try c.decode(String.self, forKey: .metaReviewSummary)
        recurringThemes = try c.decodeIfPresent([String].self, forKey: .recurringThemes) ?? []
        strengths = try c.decodeIfPresent([String].self, forKey: .strengths) ?? []
        weaknesses = try c.decodeIfPresent([String].self, forKey: .weaknesses) ?? []
        processAssessment =
            try c.decodeIfPresent(ProcessAssessment.self, forKey: .processAssessment) ?? .init()
        strategicRecommendations =
            try c.decodeIfPresent([String].self, forKey: .strategicRecommendations) ?? []
        potentialConnections =
            try c.decodeIfPresent([String].self, forKey: .potentialConnections) ?? []
    }

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "metaReviewSummary": .string(),
                "recurringThemes": .array(items: .string()),
                "strengths": .array(items: .string()),
                "weaknesses": .array(items: .string()),
                "processAssessment": .object(
                    properties: [
                        "generation": .string(),
                        "review": .string(),
                        "evolution": .string(),
                    ],
                    required: []
                ),
                "strategicRecommendations": .array(items: .string()),
                "potentialConnections": .array(items: .string()),
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

        Identify recurring themes and common strengths/weaknesses across hypotheses, assess \
        the generation/review/evolution process, surface potential connections between \
        hypotheses, and provide high-level strategic recommendations the evolution agent \
        should focus on. Return a concise overall summary plus those supporting details.
        """

    public func userPrompt(for input: MetaReviewInput) -> String {
        """
        Reviews to synthesize:

        \(input.reviewsDigest)
        """
    }

    public typealias Output = MetaReview
}
