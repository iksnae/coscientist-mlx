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

    /// Default LLM: Qwen3-4B-Instruct-2507 (4-bit). Per docs/MODELS.md — smaller and smarter
    /// than the older 7B default, instruct/non-thinking for the cleanest schema-constrained JSON.
    public static let defaultModel = ModelConfiguration(id: "mlx-community/Qwen3-4B-Instruct-2507-4bit")

    /// Load a model by configuration, downloading from Hugging Face on first use and
    /// keeping it resident in unified memory.
    public static func load(
        _ configuration: ModelConfiguration = defaultModel
    ) async throws -> MLXLanguageModel {
        let container = try await #huggingFaceLoadModelContainer(configuration: configuration)
        return MLXLanguageModel(container: container)
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
