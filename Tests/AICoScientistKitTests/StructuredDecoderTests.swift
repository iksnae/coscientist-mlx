import Testing
@testable import AICoScientistKit

/// The engine depends on `StructuredDecoder` (DIP). These tests exercise the
/// language-model-backed decoder through a mock model — no MLX, no downloads, deterministic.
@Suite("Structured decoding")
struct StructuredDecoderTests {

    @Test("Decodes a typed value from clean model JSON")
    func happyPath() async throws {
        let model = MockLanguageModel(constant: #"{"winner":"a","rationale":"clearer mechanism"}"#)
        let decoder = LanguageModelStructuredDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        #expect(verdict.winner == .a)
        #expect(verdict.rationale == "clearer mechanism")
    }

    @Test("Recovers from fenced / prose-wrapped JSON")
    func tolerant() async throws {
        let model = MockLanguageModel(constant: "Here:\n```json\n{\"winner\":\"b\",\"rationale\":\"stronger\"}\n```")
        let decoder = LanguageModelStructuredDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        #expect(verdict.winner == .b)
    }

    @Test("Throws decodingFailed when output never parses")
    func unrecoverable() async {
        let model = MockLanguageModel(constant: "I cannot answer that.")
        let decoder = LanguageModelStructuredDecoder(model: model)
        await #expect(throws: AgentError.self) {
            _ = try await decoder.decode(
                TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)
        }
    }

    @Test("Mock relays the prompt to its responder")
    func responderSeesPrompt() async throws {
        let model = MockLanguageModel { system, user in
            #"{"winner":"a","rationale":"\#(system)/\#(user)"}"#
        }
        let decoder = LanguageModelStructuredDecoder(model: model)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "S", user: "U", config: .deterministic)
        #expect(verdict.rationale == "S/U")
    }
}
