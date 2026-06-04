import Testing
@testable import AICoScientistKit

@Suite("Schema-constrained decoding")
struct SchemaConstrainedDecoderTests {

    @Test("Decodes a schema-valid response")
    func happyPath() async throws {
        let model = MockLanguageModel(constant: #"{"winner":"a","rationale":"stronger mechanism"}"#)
        let decoder = SchemaConstrainedDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        #expect(verdict.winner == .a)
    }

    @Test("Injects the schema into the prompt sent to the model")
    func schemaInPrompt() async throws {
        // Responder echoes the received user prompt into the rationale so we can inspect it.
        let model = MockLanguageModel { _, user in
            let escaped = user.replacingOccurrences(of: "\"", with: "'")
                              .replacingOccurrences(of: "\n", with: " ")
            return #"{"winner":"a","rationale":"\#(escaped)"}"#
        }
        let decoder = SchemaConstrainedDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "compare", config: .deterministic)
        #expect(verdict.rationale.contains("winner"))
        #expect(verdict.rationale.contains("one of: a|b"))
    }

    @Test("Rejects a schema-invalid response (missing required field) after repair")
    func schemaViolationThrows() async {
        let model = MockLanguageModel(constant: #"{"rationale":"no winner here"}"#)
        let decoder = SchemaConstrainedDecoder(model: model)
        await #expect(throws: AgentError.self) {
            _ = try await decoder.decode(
                TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        }
    }

    @Test("Recovers schema-valid JSON from fenced / prose-wrapped output")
    func tolerantExtraction() async throws {
        let model = MockLanguageModel(constant: "Sure:\n```json\n{\"winner\":\"b\",\"rationale\":\"ok\"}\n```")
        let decoder = SchemaConstrainedDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        #expect(verdict.winner == .b)
    }
}
