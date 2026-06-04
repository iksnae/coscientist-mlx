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
    private let metrics: DecodeMetrics?
    private let transcript: Transcript?

    public init(
        model: LanguageModel,
        maxRepairAttempts: Int = 1,
        metrics: DecodeMetrics? = nil,
        transcript: Transcript? = nil
    ) {
        self.model = model
        self.maxRepairAttempts = max(0, maxRepairAttempts)
        self.metrics = metrics
        self.transcript = transcript
    }

    public func decode<T: Decodable & Sendable>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T {
        var prompt = user
        var lastError = "no attempts made"
        var repairsUsed = 0

        for attempt in 0...maxRepairAttempts {
            let raw = try await model.generateText(system: system, user: prompt, config: config)
            await transcript?.record(system: system, user: prompt, response: raw)

            if let json = JSONExtraction.extractObject(from: raw),
               let value = try? JSONDecoder().decode(T.self, from: Data(json.utf8)) {
                await metrics?.recordSuccess(repairs: repairsUsed)
                return value
            }
            lastError = JSONExtraction.extractObject(from: raw) == nil
                ? "no JSON object found in model output"
                : "JSON did not match \(T.self)"

            if attempt < maxRepairAttempts {
                repairsUsed += 1
                prompt = Self.repairPrompt(original: user, error: lastError)
            }
        }

        await metrics?.recordFailure(repairs: repairsUsed)
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
