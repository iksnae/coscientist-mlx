/// A single tool invocation requested by the model: the tool's `name` and its decoded
/// `arguments`. Produced by `ToolCallParser` from free-text model output.
public struct ToolCall: Sendable, Equatable {
    public let name: String
    public let arguments: JSONValue

    public init(name: String, arguments: JSONValue) {
        self.name = name
        self.arguments = arguments
    }
}

/// A name-indexed set of `AgentTool`s the model may invoke during a grounded decode.
/// Pure and `Sendable` — concrete tools (network search) live in `AICoScientistRemote`.
public struct ToolRegistry: Sendable {
    private let tools: [String: any AgentTool]

    /// Index tools by name. On a name collision the first wins (deterministic).
    public init(_ tools: [any AgentTool]) {
        self.tools = Dictionary(tools.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// The tool registered under `name`, or nil if none.
    public func resolve(_ name: String) -> (any AgentTool)? { tools[name] }

    /// All registered tools (unordered).
    public var all: [any AgentTool] { Array(tools.values) }

    /// Whether any tools are registered.
    public var isEmpty: Bool { tools.isEmpty }
}

/// Extracts a tool call from a model's free-text output. The wire format is a single JSON
/// object carrying a `"tool"` key, e.g. `{"tool":"arxiv_search","args":{"query":"..."}}`,
/// reusing the tolerant `JSONExtraction` + `JSONValue` parsing. An object *without* a `tool`
/// key (such as a final schema answer) is not a tool call → returns nil.
public enum ToolCallParser {
    public static func parse(_ text: String) -> ToolCall? {
        guard let json = JSONExtraction.extractObject(from: text),
            let value = try? JSONValue.parse(json),
            case let .object(members) = value,
            let name = members["tool"]?.stringValue
        else { return nil }
        return ToolCall(name: name, arguments: members["args"] ?? .object([:]))
    }
}
