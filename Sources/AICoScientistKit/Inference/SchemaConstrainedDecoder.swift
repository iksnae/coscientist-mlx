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
    private let metrics: DecodeMetrics?

    public init(model: LanguageModel, maxRepairAttempts: Int = 1, metrics: DecodeMetrics? = nil) {
        self.model = model
        self.maxRepairAttempts = max(0, maxRepairAttempts)
        self.metrics = metrics
    }

    public func decode<T>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T where T: Decodable & Sendable & Schematized {
        let schema = T.jsonSchema
        var prompt = Self.augment(user, schema: schema)
        var lastError = "no attempts made"
        var repairsUsed = 0

        for attempt in 0...maxRepairAttempts {
            let raw = try await model.generateText(system: system, user: prompt, config: config)

            if let value = decodeIfValid(raw, schema: schema, as: T.self, error: &lastError) {
                await metrics?.recordSuccess(repairs: repairsUsed)
                return value
            }

            if attempt < maxRepairAttempts {
                repairsUsed += 1
                prompt = Self.repair(user, schema: schema, error: lastError)
            }
        }

        await metrics?.recordFailure(repairs: repairsUsed)
        throw AgentError.decodingFailed(lastError)
    }

    /// Extract → schema-validate → decode. Returns the value, or nil with `error` set.
    private func decodeIfValid<T: Decodable>(
        _ raw: String, schema: JSONSchema, as type: T.Type, error: inout String
    ) -> T? {
        guard let json = JSONExtraction.extractObject(from: raw) else {
            error = "no JSON object found in model output"
            return nil
        }
        if let value = try? JSONValue.parse(json) {
            let violations = schema.validate(value)
            if !violations.isEmpty {
                error = violations.joined(separator: "; ")
                return nil
            }
        }
        do {
            return try JSONDecoder().decode(T.self, from: Data(json.utf8))
        } catch let decodeError {
            error = String(describing: decodeError)
            return nil
        }
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
