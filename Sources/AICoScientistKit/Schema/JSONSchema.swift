/// A minimal JSON schema sufficient to describe agent outputs. It drives two things from a
/// single source of truth: a prompt-friendly rendering (to guide the model) and validation
/// of the model's parsed output (to catch violations a plain `Decodable` would miss, e.g.
/// out-of-enum strings or missing-but-required fields).
public indirect enum JSONSchema: Sendable, Equatable {
    case object(properties: [String: JSONSchema], required: [String])
    case string(enum: [String]? = nil)
    case number
    case integer
    case boolean
    case array(items: JSONSchema)

    /// Compact, deterministic shape for prompt injection — fields sorted; optional fields
    /// suffixed `?`; string enums surfaced as `string(one of: a|b)`.
    public func rendered() -> String {
        switch self {
        case let .object(properties, required):
            let fields = properties
                .map { key, sub in
                    "\"\(key)\": \(sub.rendered())\(required.contains(key) ? "" : "?")"
                }
                .sorted()
            return "{" + fields.joined(separator: ", ") + "}"
        case let .string(allowed):
            if let allowed { return "string(one of: \(allowed.joined(separator: "|")))" }
            return "string"
        case .number: return "number"
        case .integer: return "integer"
        case .boolean: return "boolean"
        case let .array(items): return "[\(items.rendered())]"
        }
    }

    /// Validate a parsed value against this schema. Returns human-readable error strings;
    /// an empty array means valid.
    public func validate(_ value: JSONValue, path: String = "$") -> [String] {
        switch self {
        case let .object(properties, required):
            guard case let .object(dict) = value else {
                return ["\(path): expected object"]
            }
            var errors: [String] = []
            for key in required where dict[key] == nil {
                errors.append("\(path).\(key): required field is missing")
            }
            for (key, sub) in properties {
                if let v = dict[key] {
                    errors += sub.validate(v, path: "\(path).\(key)")
                }
            }
            return errors

        case let .string(allowed):
            guard case let .string(s) = value else {
                return ["\(path): expected string"]
            }
            if let allowed, !allowed.contains(s) {
                return ["\(path): '\(s)' is not one of \(allowed)"]
            }
            return []

        case .number:
            if case .number = value { return [] }
            return ["\(path): expected number"]

        case .integer:
            if case let .number(d) = value, d.rounded() == d { return [] }
            return ["\(path): expected integer"]

        case .boolean:
            if case .bool = value { return [] }
            return ["\(path): expected boolean"]

        case let .array(items):
            guard case let .array(arr) = value else {
                return ["\(path): expected array"]
            }
            return arr.enumerated().flatMap { index, element in
                items.validate(element, path: "\(path)[\(index)]")
            }
        }
    }
}

/// A type that publishes a `JSONSchema` for its on-the-wire JSON form. Conforming agent
/// outputs can be schema-constrained and validated.
public protocol Schematized {
    static var jsonSchema: JSONSchema { get }
}
