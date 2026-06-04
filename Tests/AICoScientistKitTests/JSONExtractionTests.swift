import Testing
@testable import AICoScientistKit

/// Tolerant extraction is the fallback path for models without constrained decoding.
/// It must recover a JSON object from fenced, prefixed, or noisy model output, and
/// fail cleanly when there is none.
@Suite("JSON extraction")
struct JSONExtractionTests {

    @Test("Plain object passes through")
    func plain() {
        #expect(JSONExtraction.extractObject(from: #"{"winner":"a"}"#) == #"{"winner":"a"}"#)
    }

    @Test("Strips ```json code fences")
    func fenced() {
        let raw = "```json\n{\"winner\":\"b\"}\n```"
        #expect(JSONExtraction.extractObject(from: raw) == #"{"winner":"b"}"#)
    }

    @Test("Ignores prose before and after the object")
    func surroundedByProse() {
        let raw = "Sure! Here is the result:\n{\"winner\":\"a\"}\nLet me know if you need more."
        #expect(JSONExtraction.extractObject(from: raw) == #"{"winner":"a"}"#)
    }

    @Test("Handles nested braces and braces inside strings")
    func nested() {
        let raw = #"prefix {"a":{"b":1},"note":"has } brace"} suffix"#
        #expect(JSONExtraction.extractObject(from: raw) == #"{"a":{"b":1},"note":"has } brace"}"#)
    }

    @Test("Returns nil when there is no object")
    func none() {
        #expect(JSONExtraction.extractObject(from: "no json here") == nil)
        #expect(JSONExtraction.extractObject(from: "") == nil)
    }
}
