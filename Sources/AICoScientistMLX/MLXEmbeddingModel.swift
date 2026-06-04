import AICoScientistKit
import Foundation
import HuggingFace
import MLX
import MLXEmbedders
import MLXHuggingFace
import MLXLMCommon
import Tokenizers

/// MLX-backed `EmbeddingModel`, powering embedding-based proximity (M5). All MLX work stays
/// inside `EmbedderModelContainer.perform { … }`; only `[[Float]]` (Sendable) escapes, since
/// `MLXArray` is not Sendable. An `actor` to serialize GPU access.
public actor MLXEmbeddingModel: AICoScientistKit.EmbeddingModel {
    private let container: EmbedderModelContainer

    public init(container: EmbedderModelContainer) {
        self.container = container
    }

    /// Default embedder: Qwen3-Embedding-0.6B (4-bit DWQ, ~335 MB). Per docs/MODELS.md — the
    /// only top-MTEB-tier model in the Swift `qwen3` registry while staying tiny. (Note: a
    /// reported memory-growth quirk on repeated inference — we embed once per proximity phase.)
    public static let defaultModel = ModelConfiguration(id: "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ")

    /// Load an embedding model, downloading from Hugging Face on first use.
    public static func load(
        _ configuration: ModelConfiguration = defaultModel
    ) async throws -> MLXEmbeddingModel {
        let container = try await EmbedderModelFactory.shared.loadContainer(
            from: #hubDownloader(),
            using: #huggingFaceTokenizerLoader(),
            configuration: configuration,
            progressHandler: { _ in }
        )
        return MLXEmbeddingModel(container: container)
    }

    public func embed(_ texts: [String]) async throws -> [[Float]] {
        guard !texts.isEmpty else { return [] }
        return await container.perform { context in
            let tokenizer = context.tokenizer
            let encoded = texts.map { tokenizer.encode(text: $0, addSpecialTokens: true) }
            let maxLength = encoded.reduce(into: 16) { $0 = max($0, $1.count) }
            let padID = tokenizer.eosTokenId ?? 0

            let padded = stacked(
                encoded.map { ids in
                    MLXArray(ids + Array(repeating: padID, count: maxLength - ids.count))
                })
            let mask = padded .!= padID
            let tokenTypes = MLXArray.zeros(like: padded)

            let output = context.model(
                padded, positionIds: nil, tokenTypeIds: tokenTypes, attentionMask: mask)
            let pooled = context.pooling(output, mask: mask, normalize: true, applyLayerNorm: false)
            pooled.eval()
            return pooled.map { $0.asArray(Float.self) }
        }
    }
}
