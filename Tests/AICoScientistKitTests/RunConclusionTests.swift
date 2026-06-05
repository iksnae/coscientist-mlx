import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Run conclusion")
struct RunConclusionTests {

    @Test("Snapshot persists errors; a legacy snapshot without them decodes to empty")
    func errorsPersist() throws {
        let snap = RunSnapshot(
            researchGoal: "g", hypotheses: [], metrics: ExecutionMetrics(),
            clusters: [], metaReviewSummary: "", errors: ["generation: boom"])
        let decoded = try JSONDecoder().decode(
            RunSnapshot.self, from: JSONEncoder().encode(snap))
        #expect(decoded.errors == ["generation: boom"])

        var object = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(snap)) as! [String: Any]
        object.removeValue(forKey: "errors")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        #expect(try JSONDecoder().decode(RunSnapshot.self, from: legacy).errors.isEmpty)
    }

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
