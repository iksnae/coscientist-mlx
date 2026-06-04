/// Input for hypothesis generation.
public struct GenerationInput: Sendable {
    public let researchGoal: String
    public let count: Int
    public init(researchGoal: String, count: Int) {
        self.researchGoal = researchGoal
        self.count = count
    }
}

/// A single generated hypothesis with its justification.
public struct GeneratedHypothesis: Codable, Sendable, Equatable {
    public let text: String
    public let justification: String
}

/// The generation agent's output: a batch of candidate hypotheses.
public struct GeneratedHypotheses: Codable, Sendable, Equatable, Schematized {
    public let hypotheses: [GeneratedHypothesis]

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "hypotheses": .array(
                    items: .object(
                        properties: ["text": .string(), "justification": .string()],
                        required: ["text", "justification"]
                    )
                )
            ],
            required: ["hypotheses"]
        )
    }
}

/// Generates novel, testable research hypotheses for a goal. Ported from the Python
/// generation agent prompt (JSON-shape example dropped — the schema is injected by the decoder).
public struct GenerationAgent: Agent {
    public init() {}
    public let name = "HypothesisGenerator"

    public let systemPrompt = """
        You are a Hypothesis Generation Agent in an AI Co-scientist framework. Generate \
        novel, relevant research hypotheses for a given research goal, grounded in current \
        scientific knowledge.

        Each hypothesis must be:
        - Novel and original; challenging assumptions or extending current knowledge
        - Relevant to the research goal
        - Testable and falsifiable, identifying variables and relationships
        - Scientifically sound and specific
        - Balanced between ambition and feasibility

        For each hypothesis provide a concise statement and a brief justification of its \
        novelty, significance, and scientific rationale.
        """

    public func userPrompt(for input: GenerationInput) -> String {
        """
        Research goal: \(input.researchGoal)

        Generate \(input.count) distinct hypotheses.
        """
    }

    public typealias Output = GeneratedHypotheses
}
