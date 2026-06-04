/// JSON schemas for the agent output types. Kept beside the types they describe; these are
/// the single source of truth for both prompt guidance and output validation. The property
/// names must match the `Codable` keys (camelCase) so validation and decoding agree.

extension ReviewScores: Schematized {
    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "scientificSoundness": .number,
                "novelty": .number,
                "relevance": .number,
                "testability": .number,
                "clarity": .number,
                "impact": .number,
            ],
            required: [
                "scientificSoundness", "novelty", "relevance",
                "testability", "clarity", "impact",
            ]
        )
    }
}

extension TournamentJudgment: Schematized {
    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "winner": .string(enum: ["a", "b"]),
                "rationale": .string(),
            ],
            required: ["winner", "rationale"]
        )
    }
}

extension HypothesisReview: Schematized {
    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "scores": ReviewScores.jsonSchema,
                "reviewSummary": .string(),
                "safetyEthicalConcerns": .string(),
                "strengths": .array(items: .string()),
                "weaknesses": .array(items: .string()),
                "suggestions": .array(items: .string()),
            ],
            required: ["scores", "reviewSummary", "safetyEthicalConcerns"]
        )
    }
}
