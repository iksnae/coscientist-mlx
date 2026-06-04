import Foundation

/// Produces a typed, validated value from a model given a system + user prompt. The engine
/// depends on this protocol, not on any concrete decoding strategy (DIP) — so constrained
/// decoding (MLX, M2) can replace the tolerant fallback without touching agent code.
public protocol StructuredDecoder: Sendable {
    func decode<T: Decodable & Sendable>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T
}

/// Fallback decoder: prompt → tolerant JSON extraction → decode, with a bounded
/// error-fed repair retry. The primary constrained-decoding implementation arrives with
/// the MLX backend; both conform to the same protocol.
public struct LanguageModelStructuredDecoder: StructuredDecoder {
    private let model: LanguageModel
    private let maxRepairAttempts: Int

    public init(model: LanguageModel, maxRepairAttempts: Int = 1) {
        self.model = model
        self.maxRepairAttempts = max(0, maxRepairAttempts)
    }

    public func decode<T: Decodable & Sendable>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T {
        var prompt = user
        var lastError = "no attempts made"

        for _ in 0...maxRepairAttempts {
            let raw = try await model.generateText(system: system, user: prompt, config: config)

            guard let json = JSONExtraction.extractObject(from: raw) else {
                lastError = "no JSON object found in model output"
                prompt = Self.repairPrompt(original: user, error: lastError)
                continue
            }

            do {
                return try JSONDecoder().decode(T.self, from: Data(json.utf8))
            } catch {
                lastError = String(describing: error)
                prompt = Self.repairPrompt(original: user, error: lastError)
            }
        }

        throw AgentError.decodingFailed(lastError)
    }

    private static func repairPrompt(original: String, error: String) -> String {
        """
        \(original)

        Your previous response could not be parsed (\(error)). \
        Respond with ONLY a single valid JSON object, no prose or code fences.
        """
    }
}
