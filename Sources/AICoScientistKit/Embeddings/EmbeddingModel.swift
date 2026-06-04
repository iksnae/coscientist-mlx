/// Produces embedding vectors for texts. The MLX backend conforms in the adapter layer;
/// tests use a mock. Implementations should return one vector per input text.
public protocol EmbeddingModel: Sendable {
    func embed(_ texts: [String]) async throws -> [[Float]]
}
