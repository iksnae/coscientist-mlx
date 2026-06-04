import AICoScientistKit
import Foundation
import HuggingFace
import MLX
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Tokenizers

/// MLX-backed `LanguageModel`. This is the *only* place `MLX*` types appear — the domain
/// and engine depend solely on the `LanguageModel` protocol (DIP), so the core builds and
/// tests without MLX, and this backend stays swappable.
///
/// An `actor` because `MLXArray` is not `Sendable` and MLX evaluation is internally
/// serialized: one resident model behind one actor is the correct concurrency model. All
/// array work stays inside the library's `ModelContainer`; only `String` escapes here.
public actor MLXLanguageModel: AICoScientistKit.LanguageModel {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// Load a generator by catalog key (e.g. "qwen3-4b") or raw HF repo id. Catalog entries
    /// load at a **pinned commit**; a trusted-org or unverified id loads at `main` with a
    /// logged warning (see `ModelCatalog`). Defaults to the curated default generator.
    public static func load(
        _ keyOrID: String = ModelCatalog.defaultGeneratorKey
    ) async throws -> MLXLanguageModel {
        let resolved = ModelCatalog.resolve(keyOrID)
        if let warning = resolved.warning { Log.logger.warning("\(warning)") }
        let configuration = ModelConfiguration(
            id: resolved.repoID, revision: resolved.revision ?? "main")
        let container = try await #huggingFaceLoadModelContainer(configuration: configuration)
        return MLXLanguageModel(container: container)
    }

    /// Alias for callers that prefer the explicit label.
    public static func load(modelId: String) async throws -> MLXLanguageModel {
        try await load(modelId)
    }

    public func generateText(
        system: String, user: String, config: GenerationConfig
    ) async throws -> String {
        if let seed = config.seed {
            MLX.seed(seed)
        }
        let parameters = GenerateParameters(
            maxTokens: config.maxTokens,
            temperature: Float(config.temperature)
        )
        // A fresh session per call: agent calls are independent, so no history bleeds
        // between them. The session wraps the resident container; construction is cheap.
        let session = ChatSession(
            container,
            instructions: system.isEmpty ? nil : system,
            generateParameters: parameters
        )
        return try await session.respond(to: user)
    }
}
