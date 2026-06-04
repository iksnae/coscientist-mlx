/// Input for similarity analysis: the hypothesis texts (presented numbered in the prompt).
public struct ProximityInput: Sendable {
    public let hypotheses: [String]
    public init(hypotheses: [String]) {
        self.hypotheses = hypotheses
    }
}

/// A cluster of similar hypotheses, referenced by their 0-based index in the input list.
/// Using indices (not text) avoids the Python reference's fragile string-equality matching.
public struct ProximityCluster: Codable, Sendable, Equatable {
    public let clusterID: String
    public let clusterName: String
    public let memberIndices: [Int]
}

public struct ProximityResult: Codable, Sendable, Equatable, Schematized {
    public let clusters: [ProximityCluster]

    public static var jsonSchema: JSONSchema {
        .object(
            properties: [
                "clusters": .array(
                    items: .object(
                        properties: [
                            "clusterID": .string(),
                            "clusterName": .string(),
                            "memberIndices": .array(items: .integer),
                        ],
                        required: ["clusterID", "clusterName", "memberIndices"]
                    )
                )
            ],
            required: ["clusters"]
        )
    }
}

/// LLM-based similarity clustering, ported from the Python proximity agent prompt. NOTE:
/// M5 introduces embedding-based clustering as the preferred `ProximityAnalyzer`; this agent
/// remains as a parity/fallback path behind that protocol (OCP). Clusters reference input
/// indices so the engine maps them to stable hypothesis IDs.
public struct ProximityAgent: Agent {
    public init() {}
    public let name = "ProximityAnalyzer"

    public let systemPrompt = """
        You are a Proximity Agent analyzing similarity between research hypotheses to \
        maintain diversity and reduce redundancy.

        Consider each hypothesis's core concepts, key variables and relationships, \
        underlying assumptions, methodological approach, and implications. Group \
        conceptually related hypotheses into clusters; give each cluster a short \
        descriptive name. Reference hypotheses by their 0-based index from the numbered \
        list. Every hypothesis belongs to exactly one cluster (a singleton cluster is fine).
        """

    public func userPrompt(for input: ProximityInput) -> String {
        let listing = input.hypotheses.enumerated()
            .map { "\($0). \($1)" }
            .joined(separator: "\n")
        return """
            Hypotheses (index. text):

            \(listing)
            """
    }

    public typealias Output = ProximityResult
}
