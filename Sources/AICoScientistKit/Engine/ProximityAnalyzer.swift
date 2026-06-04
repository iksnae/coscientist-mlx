/// Groups hypotheses into similarity clusters. The engine depends on this protocol, so the
/// clustering strategy is swappable: an LLM agent (parity/fallback) or embeddings (M5+).
public protocol ProximityAnalyzer: Sendable {
    func cluster(_ hypotheses: [Hypothesis]) async throws -> [SimilarityCluster]
}

/// LLM-based proximity (the M3 `ProximityAgent`) as a `ProximityAnalyzer`. Index-based, so
/// it maps cleanly to stable hypothesis IDs. This is the fallback path when embeddings are
/// unavailable.
public struct AgentProximityAnalyzer: ProximityAnalyzer {
    private let decoder: any SchemaConstrainedDecoding

    public init(decoder: any SchemaConstrainedDecoding) {
        self.decoder = decoder
    }

    public func cluster(_ hypotheses: [Hypothesis]) async throws -> [SimilarityCluster] {
        guard !hypotheses.isEmpty else { return [] }
        let result = try await ProximityAgent().run(
            .init(hypotheses: hypotheses.map(\.text)), using: decoder)
        return result.clusters.map { cluster in
            let ids = cluster.memberIndices
                .filter { hypotheses.indices.contains($0) }
                .map { hypotheses[$0].id }
            return SimilarityCluster(clusterID: cluster.clusterID, memberIDs: ids)
        }
    }
}

/// Embedding-based proximity: embed each hypothesis, then cluster by cosine threshold. This
/// is the superior path over the reference's LLM-judged, string-matched clustering —
/// deterministic, no JSON parsing, and no fragile text equality. Generic over `EmbeddingModel`
/// so it is testable with a mock and MLX-free in the core.
public struct EmbeddingProximityAnalyzer<Model: EmbeddingModel>: ProximityAnalyzer {
    private let model: Model
    private let threshold: Float

    /// - Parameter threshold: cosine similarity at/above which hypotheses join a cluster.
    ///   ~0.80–0.85 suits short scientific text; tune empirically.
    public init(model: Model, threshold: Float = 0.82) {
        self.model = model
        self.threshold = threshold
    }

    public func cluster(_ hypotheses: [Hypothesis]) async throws -> [SimilarityCluster] {
        guard !hypotheses.isEmpty else { return [] }
        let vectors = try await model.embed(hypotheses.map(\.text))
        let groups = EmbeddingClusterer.cluster(vectors, threshold: threshold)
        return groups.enumerated().map { index, members in
            SimilarityCluster(
                clusterID: "cluster-\(index + 1)",
                memberIDs: members.map { hypotheses[$0].id }
            )
        }
    }
}
