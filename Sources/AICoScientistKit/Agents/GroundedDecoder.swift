/// A `SchemaConstrainedDecoding` that lets the model gather evidence from `AgentTool`s before
/// committing to a typed answer. It runs a bounded ReAct loop in free text — generate → parse
/// a tool call → execute → feed the observation back — then **delegates the final, validated
/// schema decode to a wrapped `SchemaConstrainedDecoding`**. Because it conforms to the same
/// protocol, agents and the engine consume it unchanged: grounding an agent is purely a
/// routing choice (see the grounded-router builder), not an agent change.
///
/// With zero tool calls the final user prompt is identical to the original, so a model that
/// never asks for a tool produces the same output as the inner decoder alone.
public struct GroundedDecoder: SchemaConstrainedDecoding {
    private let model: any LanguageModel
    private let tools: ToolRegistry
    private let inner: any SchemaConstrainedDecoding
    private let maxToolSteps: Int
    private let onToolCall: (@Sendable (ToolCall) -> Void)?

    public init(
        model: any LanguageModel,
        tools: ToolRegistry,
        inner: any SchemaConstrainedDecoding,
        maxToolSteps: Int = 4,
        onToolCall: (@Sendable (ToolCall) -> Void)? = nil
    ) {
        self.model = model
        self.tools = tools
        self.inner = inner
        self.maxToolSteps = max(0, maxToolSteps)
        self.onToolCall = onToolCall
    }

    public func decode<T>(
        _ type: T.Type, system: String, user: String, config: GenerationConfig
    ) async throws -> T where T: Decodable & Sendable & Schematized {
        var notes: [String] = []

        if !tools.isEmpty {
            let toolSystem = Self.toolPreamble(system: system, tools: tools.all)
            var step = 0
            while step < maxToolSteps {
                let prompt = Self.gatheringPrompt(task: user, notes: notes)
                let raw = try await model.generateText(
                    system: toolSystem, user: prompt, config: config)
                guard let call = ToolCallParser.parse(raw), let tool = tools.resolve(call.name)
                else { break }  // no (recognized) tool call → done gathering

                onToolCall?(call)
                let result = (try? await tool.call(call.arguments))
                    ?? "Tool \(call.name) returned no result."
                notes.append("\(call.name): \(result)")
                step += 1
            }
        }

        let finalUser = notes.isEmpty ? user : Self.groundedPrompt(task: user, notes: notes)
        return try await inner.decode(type, system: system, user: finalUser, config: config)
    }

    private static func toolPreamble(system: String, tools: [any AgentTool]) -> String {
        let catalog = tools.map { "- \($0.name): \($0.description)" }.joined(separator: "\n")
        return """
            \(system)

            You may call tools to gather evidence before answering. To call one, respond with \
            ONLY a single JSON object: {"tool":"<name>","args":{...}}. When you have enough \
            evidence, respond without a tool call.

            Available tools:
            \(catalog)
            """
    }

    private static func gatheringPrompt(task: String, notes: [String]) -> String {
        guard !notes.isEmpty else { return task }
        return """
            \(task)

            Tool results so far:
            \(notes.joined(separator: "\n\n"))

            Call another tool if you need more evidence, otherwise respond without a tool call.
            """
    }

    private static func groundedPrompt(task: String, notes: [String]) -> String {
        """
        \(task)

        Ground your answer in these research notes from tool calls:
        \(notes.joined(separator: "\n\n"))
        """
    }
}
