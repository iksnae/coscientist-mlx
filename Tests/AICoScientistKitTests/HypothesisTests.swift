import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Hypothesis")
struct HypothesisTests {

    @Test("Defaults match the reference (Elo 1200, empty history, zero counters)")
    func defaults() {
        let h = Hypothesis(text: "a hypothesis")
        #expect(h.eloRating == 1200)
        #expect(h.score == 0.0)
        #expect(h.reviews.isEmpty)
        #expect(h.similarityClusterID == nil)
        #expect(h.winCount == 0 && h.lossCount == 0)
    }

    @Test("Win rate is a rounded percentage and zero-safe")
    func winRate() {
        var h = Hypothesis(text: "h")
        #expect(h.winRate == 0)            // no matches → no divide-by-zero
        h.winCount = 1
        h.lossCount = 2
        #expect(h.winRate == 33.33)        // 1/3 → 33.33
    }

    @Test("Identity is by stable id, not text")
    func stableIdentity() {
        let a = Hypothesis(text: "same text")
        let b = Hypothesis(text: "same text")
        #expect(a.id != b.id)              // never collapse distinct hypotheses by text
    }

    @Test("Codable round-trips losslessly")
    func codableRoundTrip() throws {
        var h = Hypothesis(text: "round trip", eloRating: 1312, score: 0.75)
        h.similarityClusterID = "cluster-1"
        h.evolutionHistory = ["v1", "v2"]
        let data = try JSONEncoder().encode(h)
        let decoded = try JSONDecoder().decode(Hypothesis.self, from: data)
        #expect(decoded == h)
    }
}
