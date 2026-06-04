import Testing
@testable import AICoScientistKit

@Suite("Transcript")
struct TranscriptTests {

    @Test("Records interactions in order")
    func records() async {
        let t = Transcript()
        await t.record(system: "s1", user: "u1", response: "r1")
        await t.record(system: "s2", user: "u2", response: "r2")
        let all = await t.all()
        #expect(all.count == 2)
        #expect(all.first == .init(system: "s1", user: "u1", response: "r1"))
        #expect(all.last?.response == "r2")
    }

    @Test("Decoder logs each model call (system, schema-augmented user, response)")
    func decoderLogs() async throws {
        let transcript = Transcript()
        let decoder = SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: #"{"winner":"a","rationale":"x"}"#),
            transcript: transcript)
        _ = try await decoder.decode(
            TournamentJudgment.self, system: "judge", user: "a vs b", config: .deterministic)

        let entries = await transcript.all()
        #expect(entries.count == 1)
        #expect(entries.first?.system == "judge")
        #expect(entries.first?.user.contains("a vs b") == true)   // original prompt
        #expect(entries.first?.user.contains("winner") == true)   // injected schema
        #expect(entries.first?.response.contains("rationale") == true)
    }
}
