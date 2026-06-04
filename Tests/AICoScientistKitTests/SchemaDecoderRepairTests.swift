import Testing
@testable import AICoScientistKit

/// Returns a queued sequence of responses (last one repeats), so we can force a repair.
private actor SequencedModel: LanguageModel {
    private let responses: [String]
    private var index = 0

    init(_ responses: [String]) { self.responses = responses }

    func generateText(system: String, user: String, config: GenerationConfig) async throws -> String {
        let response = responses[Swift.min(index, responses.count - 1)]
        index += 1
        return response
    }
}

@Suite("Repair-retry telemetry")
struct SchemaDecoderRepairTests {

    @Test("Clean first decode records zero repairs")
    func cleanZero() async throws {
        let metrics = DecodeMetrics()
        let decoder = SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: #"{"winner":"a","rationale":"x"}"#), metrics: metrics)
        _ = try await decoder.decode(TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        #expect(await metrics.snapshot() == .init(decodes: 1, repairs: 0, failures: 0))
    }

    @Test("One repair counted when first reply is invalid, second valid")
    func oneRepair() async throws {
        let metrics = DecodeMetrics()
        let model = SequencedModel(["not json at all", #"{"winner":"a","rationale":"final"}"#])
        let decoder = SchemaConstrainedDecoder(model: model, metrics: metrics)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        #expect(verdict.winner == .a)
        #expect(await metrics.snapshot() == .init(decodes: 1, repairs: 1, failures: 0))
    }

    @Test("Schema violation on first try, valid on retry, counts one repair")
    func schemaViolationThenValid() async throws {
        let metrics = DecodeMetrics()
        // First is valid JSON but violates the enum; second is correct.
        let model = SequencedModel([#"{"winner":"c","rationale":"x"}"#, #"{"winner":"b","rationale":"ok"}"#])
        let decoder = SchemaConstrainedDecoder(model: model, metrics: metrics)
        let verdict = try await decoder.decode(
            TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        #expect(verdict.winner == .b)
        #expect(await metrics.snapshot() == .init(decodes: 1, repairs: 1, failures: 0))
    }

    @Test("Unrecoverable decode records a failure with all retries used")
    func failureAllRetries() async {
        let metrics = DecodeMetrics()
        let decoder = SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: "never json"), maxRepairAttempts: 2, metrics: metrics)
        await #expect(throws: AgentError.self) {
            _ = try await decoder.decode(TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
        }
        #expect(await metrics.snapshot() == .init(decodes: 0, repairs: 2, failures: 1))
    }
}
