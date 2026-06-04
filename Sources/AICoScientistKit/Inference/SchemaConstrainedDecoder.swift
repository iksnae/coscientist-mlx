import Foundation

/// Produces a typed value whose JSON form is constrained by a `JSONSchema`. Unlike
/// `StructuredDecoder`, the output type must publish a schema (`Schematized`), which is used
/// to (1) guide the model via the prompt and (2) validate the parsed output before decoding
/// — catching violations a plain `Decodable` would miss or mis-handle.
public protocol SchemaConstrainedDecoding: Sendable {
    func decode<T>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T where T: Decodable & Sendable & Schematized
}

/// Schema-guided decoder backed by any `LanguageModel`: inject schema → generate → extract
/// → validate against schema → decode, with a bounded, error-fed repair retry. This is the
/// portable, fully-testable form of schema-constrained decoding. A GPU logit-masking
/// implementation (which *prevents* invalid tokens rather than rejecting after the fact)
/// can conform to the same protocol later in the MLX layer.
public struct SchemaConstrainedDecoder: SchemaConstrainedDecoding {
    private let model: LanguageModel
    private let maxRepairAttempts: Int

    public init(model: LanguageModel, maxRepairAttempts: Int = 1) {
        self.model = model
        self.maxRepairAttempts = max(0, maxRepairAttempts)
    }

    public func decode<T>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T where T: Decodable & Sendable & Schematized {
        let schema = T.jsonSchema
        var prompt = Self.augment(user, schema: schema)
        var lastError = "no attempts made"

        for _ in 0...maxRepairAttempts {
            let raw = try await model.generateText(system: system, user: prompt, config: config)

            guard let json = JSONExtraction.extractObject(from: raw) else {
                lastError = "no JSON object found in model output"
                prompt = Self.repair(user, schema: schema, error: lastError)
                continue
            }

            // Validate the parsed value against the schema before decoding so we can give
            // the model a precise, actionable error on retry.
            if let value = try? JSONValue.parse(json) {
                let violations = schema.validate(value)
                if !violations.isEmpty {
                    lastError = violations.joined(separator: "; ")
                    prompt = Self.repair(user, schema: schema, error: lastError)
                    continue
                }
            }

            do {
                return try JSONDecoder().decode(T.self, from: Data(json.utf8))
            } catch {
                lastError = String(describing: error)
                prompt = Self.repair(user, schema: schema, error: lastError)
            }
        }

        throw AgentError.decodingFailed(lastError)
    }

    private static func augment(_ user: String, schema: JSONSchema) -> String {
        """
        \(user)

        Respond with ONLY a single JSON object matching this schema \
        (no prose, no code fences):
        \(schema.rendered())
        """
    }

    private static func repair(_ user: String, schema: JSONSchema, error: String) -> String {
        """
        \(user)

        Your previous response was invalid: \(error).
        Respond with ONLY a single JSON object matching this schema:
        \(schema.rendered())
        """
    }
}
