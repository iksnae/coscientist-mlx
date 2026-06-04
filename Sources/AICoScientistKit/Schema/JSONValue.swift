import Foundation

/// A parsed JSON value. Used to validate model output against a `JSONSchema` before
/// decoding into a typed struct. Kept dependency-free and `Sendable`.
public enum JSONValue: Sendable, Equatable {
    case object([String: JSONValue])
    case array([JSONValue])
    case string(String)
    case number(Double)
    case bool(Bool)
    case null

    /// Parse JSON text into a `JSONValue`. Throws on malformed input.
    public static func parse(_ text: String) throws -> JSONValue {
        let object = try JSONSerialization.jsonObject(
            with: Data(text.utf8), options: [.fragmentsAllowed]
        )
        return convert(object)
    }

    private static func convert(_ any: Any) -> JSONValue {
        if any is NSNull { return .null }
        if let number = any as? NSNumber {
            // NSNumber represents both Bool and numeric JSON; disambiguate via CFBoolean.
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return .bool(number.boolValue)
            }
            return .number(number.doubleValue)
        }
        if let string = any as? String { return .string(string) }
        if let dict = any as? [String: Any] { return .object(dict.mapValues(convert)) }
        if let array = any as? [Any] { return .array(array.map(convert)) }
        return .null
    }
}
