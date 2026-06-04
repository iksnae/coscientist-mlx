import Testing
@testable import AICoScientistKit

@Suite("JSONValue parsing")
struct JSONValueTests {

    @Test("Parses a flat object with mixed scalar types")
    func flatObject() throws {
        let v = try JSONValue.parse(#"{"name":"x","age":3,"ok":true,"missing":null}"#)
        #expect(v == .object([
            "name": .string("x"),
            "age": .number(3),
            "ok": .bool(true),
            "missing": .null,
        ]))
    }

    @Test("Distinguishes bool from number (JSON true is not 1)")
    func boolNotNumber() throws {
        let v = try JSONValue.parse(#"{"flag":true,"count":1}"#)
        guard case .object(let d) = v else { Issue.record("not object"); return }
        #expect(d["flag"] == .bool(true))
        #expect(d["count"] == .number(1))
    }

    @Test("Parses nested objects and arrays")
    func nested() throws {
        let v = try JSONValue.parse(#"{"a":{"b":[1,2]},"c":["x"]}"#)
        #expect(v == .object([
            "a": .object(["b": .array([.number(1), .number(2)])]),
            "c": .array([.string("x")]),
        ]))
    }

    @Test("Throws on malformed JSON")
    func malformed() {
        #expect(throws: Error.self) { _ = try JSONValue.parse("{not json") }
    }
}
