import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Run state reducer")
struct RunStateTests {

    private func hyp(_ elo: Int) -> Hypothesis { Hypothesis(text: "h", eloRating: elo) }

    @Test("started resets and seeds the run")
    func started() {
        var s = RunState()
        s.phase = "stale"; s.activity = [ActivityEvent(step: 9, progress: progress())]
        let id = UUID()
        s = runReducer(s, RunAction.started(
            studyID: id, maxIterations: 4, downloadingNeeded: true, status: "Loading…"))
        #expect(s.runningStudyID == id)
        #expect(s.maxIterations == 4)
        #expect(s.downloadingNeeded)
        #expect(s.status == "Loading…")
        #expect(s.phase.isEmpty)          // reset
        #expect(s.activity.isEmpty)       // reset
    }

    @Test("progress updates fields + appends an activity row and an Elo timeline point")
    func progress() {
        var s = runReducer(RunState(), RunAction.started(
            studyID: UUID(), maxIterations: 2, downloadingNeeded: false, status: "x"))
        s = runReducer(s, RunAction.progress(progress(phase: "tournament", completed: 2, total: 5, elos: [1300, 1200])))
        #expect(s.phase == "tournament")
        #expect(s.completed == 2 && s.total == 5)
        #expect(s.activity.count == 1)
        #expect(s.timeline.count == 1)
        #expect(s.timeline.first?.topElo == 1300)
        #expect(s.phaseFraction == 0.4)
    }

    @Test("activity log is capped at 200")
    func activityCap() {
        var s = RunState()
        for _ in 0..<250 { s = runReducer(s, RunAction.progress(progress())) }
        #expect(s.activity.count == 200)
    }

    @Test("finished sets the outcome; cleared ends the run")
    func finishedCleared() {
        var s = runReducer(RunState(), RunAction.started(
            studyID: UUID(), maxIterations: 1, downloadingNeeded: false, status: "x"))
        s = runReducer(s, RunAction.finished(
            status: "Done", hypotheses: [hyp(1300)], metrics: ExecutionMetrics(), errors: ["e"]))
        #expect(s.status == "Done")
        #expect(s.hypotheses.count == 1)
        #expect(s.errors == ["e"])
        #expect(s.phase == "done")
        s = runReducer(s, RunAction.cleared)
        #expect(s.runningStudyID == nil)
    }

    private func progress(
        phase: String = "generation", completed: Int = 0, total: Int = 0, elos: [Int] = []
    ) -> WorkflowProgress {
        WorkflowProgress(
            phase: phase, iteration: 0, detail: "", completed: completed, total: total,
            hypotheses: elos.map(hyp), metrics: ExecutionMetrics())
    }
}
