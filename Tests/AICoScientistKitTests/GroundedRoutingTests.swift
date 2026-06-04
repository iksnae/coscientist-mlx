import Testing
@testable import AICoScientistKit

@Suite("Grounded routing")
struct GroundedRoutingTests {

    private struct StubTool: AgentTool {
        let name = "stub_search"
        let description = "Stub search tool for tests."
        var parameters: JSONSchema { .object(properties: ["query": .string()], required: ["query"]) }
        func call(_ arguments: JSONValue) async throws -> String { "STUBHIT" }
    }

    private let toolCall = #"{"tool":"stub_search","args":{"query":"q"}}"#

    // Loop model: ask for the tool once, then stop. Inner model: encode whether the tool
    // result (STUBHIT) reached the final decode.
    private func loopModel() -> MockLanguageModel {
        MockLanguageModel { _, user in user.contains("STUBHIT") ? "done" : self.toolCall }
    }
    private func judgeBase() -> SchemaConstrainedDecoder {
        SchemaConstrainedDecoder(model: MockLanguageModel { _, user in
            let winner = user.contains("STUBHIT") ? "a" : "b"
            return #"{"winner":"\#(winner)","rationale":"r"}"#
        })
    }

    @Test("Grounded router grounds generation + reflection, leaves other roles on the base")
    func routesGroundedRolesOnly() async throws {
        let router = GroundedDecoder.router(
            base: judgeBase(), model: loopModel(), tools: ToolRegistry([StubTool()]))

        for grounded in [AgentRole.generation, .reflection] {
            let v = try await router.decoder(for: grounded)
                .decode(TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
            #expect(v.winner == .a)  // tool result reached the decode
        }
        for plain in [AgentRole.tournament, .ranking, .evolution, .metaReview, .proximity] {
            let v = try await router.decoder(for: plain)
                .decode(TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
            #expect(v.winner == .b)  // base decoder, ungrounded
        }
    }

    @Test("With no tools the router falls back to the base for every role (unchanged)")
    func emptyToolsIsBaseEverywhere() async throws {
        let router = GroundedDecoder.router(
            base: judgeBase(), model: loopModel(), tools: ToolRegistry([]))
        for role in AgentRole.allCases {
            let v = try await router.decoder(for: role)
                .decode(TournamentJudgment.self, system: "s", user: "u", config: .deterministic)
            #expect(v.winner == .b)  // never grounded
        }
    }

    @Test("GenerationAgent run through the grounded decoder yields grounded output")
    func generationAgentGrounded() async throws {
        let innerModel = MockLanguageModel { _, user in
            let text = user.contains("STUBHIT") ? "grounded-hyp" : "ungrounded-hyp"
            return #"{"hypotheses":[{"text":"\#(text)","justification":"j"}]}"#
        }
        let grounded = GroundedDecoder(
            model: loopModel(), tools: ToolRegistry([StubTool()]),
            inner: SchemaConstrainedDecoder(model: innerModel))

        let out = try await GenerationAgent().run(
            GenerationInput(researchGoal: "g", count: 1), using: grounded, config: .deterministic)
        #expect(out.hypotheses.first?.text == "grounded-hyp")
    }
}
