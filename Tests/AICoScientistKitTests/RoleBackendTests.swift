import Testing
@testable import AICoScientistKit

@Suite("Role backend")
struct RoleBackendTests {

    private func decoder(_ winner: String) -> SchemaConstrainedDecoder {
        SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: #"{"winner":"\#(winner)","rationale":"r"}"#))
    }

    private func decode(
        _ router: any DecoderRouting, _ role: AgentRole
    ) async throws -> TournamentJudgment {
        try await router.decoder(for: role)
            .decode(TournamentJudgment.self, system: "", user: "", config: .deterministic)
    }

    @Test("Remote-assigned roles use makeRemote(id); local + unassigned roles use the base")
    func routesByBackend() async throws {
        let router = RoleDecoderRouter.backed(
            default: decoder("a"),
            backends: [.reflection: .remote("gpt-4o"), .generation: .local],
            makeRemote: { _ in self.decoder("b") })

        #expect(try await decode(router, .reflection).winner == .b)   // remote
        #expect(try await decode(router, .generation).winner == .a)   // .local → base
        #expect(try await decode(router, .tournament).winner == .a)   // unassigned → base
    }

    @Test("Empty backends ⇒ base for every role (local-first)")
    func emptyIsAllBase() async throws {
        let router = RoleDecoderRouter.backed(
            default: decoder("a"), backends: [:], makeRemote: { _ in self.decoder("b") })
        for role in AgentRole.allCases {
            #expect(try await decode(router, role).winner == .a)
        }
    }

    @Test("RoleBackend is Equatable across local and remote")
    func equatable() {
        #expect(RoleBackend.local == .local)
        #expect(RoleBackend.remote("gpt-4o") == .remote("gpt-4o"))
        #expect(RoleBackend.remote("gpt-4o") != .remote("gpt-4o-mini"))
        #expect(RoleBackend.local != .remote("gpt-4o"))
    }
}
