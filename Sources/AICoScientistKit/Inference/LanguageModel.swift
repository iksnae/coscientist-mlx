import Foundation

/// Sampling configuration for a single generation request. Backend-agnostic so the
/// domain layer never imports MLX (DIP). `seed` + `temperature: 0` make tests deterministic.
public struct GenerationConfig: Sendable, Equatable {
    public var temperature: Double
    public var maxTokens: Int
    public var seed: UInt64?

    public init(temperature: Double = 0.0, maxTokens: Int = 1024, seed: UInt64? = nil) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.seed = seed
    }

    /// Greedy, seeded — reproducible output for assertions and parity runs.
    public static let deterministic = GenerationConfig(temperature: 0.0, seed: 0)
}

/// Typed errors surfaced by the inference layer. The engine records these in
/// `WorkflowResult.errors` and continues; it never crashes on a model hiccup.
public enum AgentError: Error, Equatable, Sendable {
    case generationFailed(String)
    case decodingFailed(String)
    case notImplemented(String)
}

/// The single abstraction the engine depends on for text generation. Concrete backends
/// (MLX in M1, a remote model, or the mock below) conform to this — keeping `MLX*` types
/// out of the core entirely.
public protocol LanguageModel: Sendable {
    func generateText(
        system: String, user: String, config: GenerationConfig
    ) async throws -> String
}

/// Deterministic in-memory model for unit tests — no GPU, no downloads. Either supply a
/// responder closure of `(system, user) -> String`, or a constant reply.
public struct MockLanguageModel: LanguageModel {
    public typealias Responder = @Sendable (_ system: String, _ user: String) -> String

    private let responder: Responder

    public init(responder: @escaping Responder) {
        self.responder = responder
    }

    public init(constant text: String) {
        self.responder = { _, _ in text }
    }

    public func generateText(
        system: String, user: String, config: GenerationConfig
    ) async throws -> String {
        responder(system, user)
    }
}
