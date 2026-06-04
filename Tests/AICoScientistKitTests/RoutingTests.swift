import Testing
@testable import AICoScientistKit

@Suite("Decoder routing")
struct RoutingTests {

    private func decoder(_ winner: String) -> SchemaConstrainedDecoder {
        SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: #"{"winner":"\#(winner)","rationale":"r"}"#))
    }

    @Test("RoleDecoderRouter returns the override for a role, else the default")
    func roleRouting() async throws {
        let router = RoleDecoderRouter(default: decoder("a"), overrides: [.tournament: decoder("b")])
        let viaTournament = try await router.decoder(for: .tournament)
            .decode(TournamentJudgment.self, system: "", user: "", config: .deterministic)
        let viaGeneration = try await router.decoder(for: .generation)
            .decode(TournamentJudgment.self, system: "", user: "", config: .deterministic)
        #expect(viaTournament.winner == .b)   // routed to the override
        #expect(viaGeneration.winner == .a)   // fell back to the default
    }

    @Test("StaticDecoderRouter returns the same decoder for every role")
    func staticRouting() async throws {
        let router = StaticDecoderRouter(decoder("a"))
        for role in AgentRole.allCases {
            let v = try await router.decoder(for: role)
                .decode(TournamentJudgment.self, system: "", user: "", config: .deterministic)
            #expect(v.winner == .a)
        }
    }
}
