import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Activity feed")
struct ActivityEventTests {

    private func progress(_ phase: String, detail: String = "", elos: [Int] = []) -> WorkflowProgress {
        WorkflowProgress(
            phase: phase, iteration: 0, detail: detail,
            hypotheses: elos.map { Hypothesis(text: "h", eloRating: $0) },
            metrics: ExecutionMetrics())
    }

    @Test("feed maps phases to kinds, monotonic steps, and pool/Elo")
    func feedDerives() {
        let events = ActivityEvent.feed(from: [
            progress("generation", elos: [1200, 1210]),
            progress("reflection", detail: "review 1/2"),
            progress("tournament", detail: "match 1/3: A wins", elos: [1230, 1190]),
        ])
        #expect(events.count == 3)
        #expect(events.map(\.step) == [0, 1, 2])
        #expect(events[0].kind == .generation)
        #expect(events[0].poolSize == 2)
        #expect(events[0].topElo == 1210)
        #expect(events[1].kind == .reflection)
        #expect(events[1].detail == "review 1/2")
        #expect(events[1].poolSize == nil)   // no hypotheses in this snapshot
        #expect(events[2].kind == .tournament)
        #expect(events[2].topElo == 1230)
    }

    @Test("unknown phase falls back to .other")
    func unknownKind() {
        #expect(ActivityEvent.Kind(phase: "mystery") == .other)
        #expect(ActivityEvent.Kind(phase: "metaReview") == .metaReview)
    }

    @Test("RunSnapshot round-trips its activity log")
    func snapshotRoundTrip() throws {
        let event = ActivityEvent(step: 0, progress: progress("generation", elos: [1200]))
        let snap = RunSnapshot(
            researchGoal: "g", hypotheses: [], metrics: ExecutionMetrics(),
            clusters: [], metaReviewSummary: "", activity: [event])
        let decoded = try JSONDecoder().decode(
            RunSnapshot.self, from: JSONEncoder().encode(snap))
        #expect(decoded.activity == [event])
    }

    @Test("A legacy snapshot without an activity field decodes to an empty log")
    func legacyDecodes() throws {
        let snap = RunSnapshot(
            researchGoal: "g", hypotheses: [], metrics: ExecutionMetrics(),
            clusters: [], metaReviewSummary: "",
            activity: [ActivityEvent(step: 0, progress: progress("generation"))])
        var object = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(snap)) as! [String: Any]
        object.removeValue(forKey: "activity")
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(RunSnapshot.self, from: legacy)
        #expect(decoded.activity.isEmpty)
    }
}
