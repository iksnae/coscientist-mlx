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

    // MARK: - Reasoning ("thinking") model robustness (validated on-device with Qwen3)

    @Test("Skips an empty <think></think> block before the JSON")
    func emptyThinkBlock() {
        let raw = "<think>\n</think>\n\n{\"winner\":\"a\"}"
        #expect(JSONExtraction.extractObject(from: raw) == #"{"winner":"a"}"#)
    }

    @Test("Ignores braces inside a <think> block (the real trap)")
    func bracesInsideThink() {
        let raw = #"<think>maybe {"winner":"b"} is right, reconsidering…</think>{"winner":"a","rationale":"final"}"#
        #expect(JSONExtraction.extractObject(from: raw) == #"{"winner":"a","rationale":"final"}"#)
    }

    @Test("Handles multiple think blocks and surrounding prose")
    func multipleThinkBlocks() {
        let raw = "<think>step 1 {x}</think> hmm <think>step 2 {y}</think> Answer: {\"ok\":true}"
        #expect(JSONExtraction.extractObject(from: raw) == #"{"ok":true}"#)
    }

    @Test("Think-block stripping is case-insensitive and spans newlines")
    func caseInsensitiveMultiline() {
        let raw = "<Think>\nline1 {nope}\nline2\n</THINK>\n{\"a\":1}"
        #expect(JSONExtraction.extractObject(from: raw) == #"{"a":1}"#)
    }

    @Test("Plain JSON with no think block is unchanged")
    func noThinkUnchanged() {
        #expect(JSONExtraction.extractObject(from: #"{"a":1}"#) == #"{"a":1}"#)
    }
}
