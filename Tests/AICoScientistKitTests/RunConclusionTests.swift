import Testing
@testable import AICoScientistKit

@Suite("Run conclusion")
struct RunConclusionTests {

    @Test("Conclusion surfaces the top hypothesis + synthesis")
    func conclusion() {
        let snapshot = RunSnapshot(
            researchGoal: "g",
            hypotheses: [
                Hypothesis(text: "Top idea", eloRating: 1300),
                Hypothesis(text: "Runner up", eloRating: 1200),
            ],
            metrics: ExecutionMetrics(), clusters: [], metaReviewSummary: "the synthesis")
        let c = snapshot.conclusion
        #expect(c.hasResult)
        #expect(c.topHypothesis == "Top idea")
        #expect(c.topElo == 1300)
        #expect(c.synthesis == "the synthesis")
    }

    @Test("Empty snapshot has no result")
    func empty() {
        let c = RunSnapshot(
            researchGoal: "g", hypotheses: [], metrics: ExecutionMetrics(),
            clusters: [], metaReviewSummary: "").conclusion
        #expect(!c.hasResult)
        #expect(c.topHypothesis == nil)
        #expect(c.synthesis.isEmpty)
    }
}
