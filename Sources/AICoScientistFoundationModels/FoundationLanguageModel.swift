import AICoScientistKit
import Foundation

#if canImport(FoundationModels)
    import FoundationModels
#endif

/// Apple Foundation Models backend. The availability check and the model factory live here so
/// callers (CLI/app) never need their own `canImport`/`@available` gates; the actual
/// `LanguageModel` conformance is compiled only where the framework exists.
public enum FoundationModelsBackend {
    /// Whether the on-device Apple model is usable right now — the framework is present, the OS
    /// supports it, and Apple Intelligence is available on this device.
    public static var isAvailable: Bool {
        #if canImport(FoundationModels)
            if #available(macOS 26.0, iOS 26.0, *) {
                if case .available = SystemLanguageModel.default.availability { return true }
            }
            return false
        #else
            return false
        #endif
    }

    /// An FM-backed `LanguageModel`, or `nil` when unavailable — so the CLI/app can select the
    /// backend without their own `canImport` gates (`InferenceBackend.resolve` decides whether
    /// to ask for it).
    public static func makeModel() -> (any LanguageModel)? {
        #if canImport(FoundationModels)
            if #available(macOS 26.0, iOS 26.0, *), isAvailable {
                return FoundationLanguageModel()
            }
        #endif
        return nil
    }
}

#if canImport(FoundationModels)

    /// A `LanguageModel` over Apple's on-device `LanguageModelSession`. Structured output is
    /// still produced by our `SchemaConstrainedDecoder` layered on top of this plain text
    /// generation (one decode path), and tools work via the M6 `GroundedDecoder` loop.
    @available(macOS 26.0, iOS 26.0, *)
    public struct FoundationLanguageModel: LanguageModel {
        public init() {}

        public func generateText(
            system: String, user: String, config: GenerationConfig
        ) async throws -> String {
            let session = LanguageModelSession(instructions: system)
            let options = GenerationOptions(
                temperature: config.temperature, maximumResponseTokens: config.maxTokens)
            let response = try await session.respond(to: user, options: options)
            return response.content
        }
    }

#endif
