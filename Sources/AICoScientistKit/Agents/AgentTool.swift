/// A capability an agent can invoke while reasoning — e.g. literature or web search — so
/// hypotheses and novelty judgments are grounded in real sources rather than parametric guesses.
///
/// Pure protocol: concrete network tools live in `AICoScientistRemote`; an Apple Foundation
/// Models backend can map the same shape to its native `Tool` calling.
public protocol AgentTool: Sendable {
    /// Stable identifier the model uses to invoke the tool.
    var name: String { get }
    /// What the tool does and when to use it (surfaced to the model).
    var description: String { get }
    /// JSON Schema describing the tool's arguments.
    var parameters: JSONSchema { get }
    /// Execute the tool and return a text result to feed back to the model.
    func call(_ arguments: JSONValue) async throws -> String
}

extension JSONValue {
    /// The string payload, if this value is a string.
    public var stringValue: String? {
        if case let .string(value) = self { return value }
        return nil
    }

    /// The numeric payload, if this value is a number.
    public var numberValue: Double? {
        if case let .number(value) = self { return value }
        return nil
    }

    /// Member access for object values.
    public subscript(key: String) -> JSONValue? {
        if case let .object(members) = self { return members[key] }
        return nil
    }
}
