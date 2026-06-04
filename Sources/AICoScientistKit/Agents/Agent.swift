/// A single-responsibility agent: it owns a role (`systemPrompt`) and how to turn a typed
/// `Input` into a user prompt. Decoding is delegated to a `SchemaConstrainedDecoding` — so
/// agents carry no inference or parsing logic, and the schema for `Output` drives both the
/// prompt contract and validation (M2). New agents are added by conformance (OCP).
public protocol Agent: Sendable {
    associatedtype Input: Sendable
    associatedtype Output: Decodable & Sendable & Schematized

    /// Stable identifier, mirroring the Python `agent_name`.
    var name: String { get }
    /// The agent's role/criteria. Output shape is supplied separately via the schema.
    var systemPrompt: String { get }
    /// Render the task-specific user prompt from typed input.
    func userPrompt(for input: Input) -> String
}

extension Agent {
    /// Run the agent: build the prompt, then let the schema-constrained decoder produce a
    /// validated, typed `Output`.
    public func run(
        _ input: Input,
        using decoder: some SchemaConstrainedDecoding,
        config: GenerationConfig = .deterministic
    ) async throws -> Output {
        try await decoder.decode(
            Output.self, system: systemPrompt, user: userPrompt(for: input), config: config
        )
    }
}
