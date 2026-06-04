import Testing
@testable import AICoScientistKit

@Suite("Hypothesis inspector")
struct HypothesisDetailTests {

    private func review() -> HypothesisReview {
        HypothesisReview(
            scores: ReviewScores(
                scientificSoundness: 0.8, novelty: 0.6, relevance: 0.7,
                testability: 0.5, clarity: 0.9, impact: 0.4),
            reviewSummary: "solid", strengths: ["s1"], weaknesses: ["w1"], suggestions: ["sg1"])
    }

    private func sample() -> Hypothesis {
        Hypothesis(
            text: "H", eloRating: 1275, reviews: [review(), review()], score: 0.72,
            similarityClusterID: "c1", evolutionHistory: ["seed", "evolved"],
            winCount: 3, lossCount: 1)
    }

    @Test("HypothesisDetail projects metrics, latest review, cluster, and lineage")
    func projects() {
        let d = HypothesisDetail(sample())
        #expect(d.eloRating == 1275)
        #expect(d.totalMatches == 4)
        #expect(d.winRate == 75.0)
        #expect(d.clusterID == "c1")
        #expect(d.lineage == ["seed", "evolved"])
        #expect(d.reviewCount == 2)
        #expect(d.latestReview?.reviewSummary == "solid")
        #expect((d.latestReview?.scores.overall ?? 0) > 0)
    }

    @Test("resolve maps a hypothesis id to its detail")
    func resolveHypothesis() {
        let h = sample()
        #expect(GraphSelection.resolve(nodeID: h.id.uuidString, in: [h]) == .hypothesis(HypothesisDetail(h)))
    }

    @Test("resolve maps a cluster id to its member count")
    func resolveCluster() {
        let h = sample()
        #expect(GraphSelection.resolve(nodeID: "cluster:c1", in: [h]) == .cluster(id: "c1", memberCount: 1))
    }

    @Test("resolve maps a phase id to an operation, and nil for unknown")
    func resolveOperationAndUnknown() {
        #expect(GraphSelection.resolve(nodeID: "reflection", in: []) == .operation(phase: "reflection"))
        #expect(GraphSelection.resolve(nodeID: "not-a-node", in: []) == nil)
    }
}
