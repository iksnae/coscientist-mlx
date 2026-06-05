import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Study routing + model compatibility")
struct StudyRoutingTests {

    private func dec(_ winner: String) -> SchemaConstrainedDecoder {
        SchemaConstrainedDecoder(
            model: MockLanguageModel(constant: #"{"winner":"\#(winner)","rationale":"r"}"#))
    }
    private func decode(
        _ router: any DecoderRouting, _ role: AgentRole
    ) async throws -> TournamentJudgment {
        try await router.decoder(for: role)
            .decode(TournamentJudgment.self, system: "", user: "", config: .deterministic)
    }

    @Test("Generator backs generation/evolution/ranking/meta; reviewer backs reflection+tournament")
    func routesGeneratorAndReviewer() async throws {
        let router = StudyRouting.router(
            generator: .onDevice("g"), reviewer: .hosted("rev"),
            makeOnDevice: { _ in self.dec("a") },
            makeHosted: { _ in self.dec("b") })
        #expect(try await decode(router, .generation).winner == .a)
        #expect(try await decode(router, .evolution).winner == .a)
        #expect(try await decode(router, .ranking).winner == .a)
        #expect(try await decode(router, .metaReview).winner == .a)
        #expect(try await decode(router, .reflection).winner == .b)
        #expect(try await decode(router, .tournament).winner == .b)
    }

    @Test("All on-device when generator and reviewer are both on-device (local-first)")
    func allOnDevice() async throws {
        let router = StudyRouting.router(
            generator: .onDevice("g"), reviewer: .onDevice("g"),
            makeOnDevice: { _ in self.dec("a") }, makeHosted: { _ in self.dec("b") })
        for role in AgentRole.allCases {
            #expect(try await decode(router, role).winner == .a)
        }
    }

    @Test("ModelChoice round-trips via Codable")
    func choiceCodable() throws {
        for choice in [ModelChoice.onDevice("qwen3-4b"), .hosted("gpt-4o")] {
            let back = try JSONDecoder().decode(
                ModelChoice.self, from: JSONEncoder().encode(choice))
            #expect(back == choice)
        }
    }

    @Test("Catalog model RAM compatibility: insufficient / tight / comfortable")
    func compatibility() {
        let model = ModelCatalog.generators.first { $0.key == "qwen3-8b" }!  // minRAMGB 16
        #expect(model.fit(deviceRAMGB: 8) == .insufficient)
        #expect(model.fit(deviceRAMGB: 16) == .tight)
        #expect(model.fit(deviceRAMGB: 64) == .comfortable)
    }

    @Test("Catalog carries strengths + tier from the model research")
    func researchData() {
        for model in ModelCatalog.generators {
            #expect(!model.strengths.isEmpty)
            #expect(!model.tier.isEmpty)
        }
    }
}
