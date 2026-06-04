import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Run persistence")
struct RunStoreTests {

    private func sampleSnapshot() -> RunSnapshot {
        var h = Hypothesis(text: "persisted hypothesis", eloRating: 1275, score: 0.82)
        h.similarityClusterID = "cluster-1"
        h.evolutionHistory = ["v0"]
        return RunSnapshot(
            researchGoal: "test goal",
            hypotheses: [h],
            metrics: ExecutionMetrics(hypothesisCount: 1, reviewsCount: 2, tournamentsCount: 6, evolutionsCount: 1),
            clusters: [SimilarityCluster(clusterID: "cluster-1", memberIDs: [h.id])],
            metaReviewSummary: "synthesis"
        )
    }

    @Test("Round-trips a snapshot through disk losslessly")
    func roundTrip() throws {
        let snapshot = sampleSnapshot()
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("run-\(snapshot.hypotheses[0].id).json")
        defer { try? FileManager.default.removeItem(at: url) }

        try RunStore.save(snapshot, to: url)
        let loaded = try RunStore.load(from: url)
        #expect(loaded == snapshot)
    }

    @Test("Builds a snapshot from a WorkflowResult")
    func fromResult() {
        let h = Hypothesis(text: "h")
        let result = WorkflowResult(
            topRankedHypotheses: [h],
            metaReviewSummary: "sum",
            clusters: [SimilarityCluster(clusterID: "c1", memberIDs: [h.id])],
            metrics: ExecutionMetrics(hypothesisCount: 1),
            totalWorkflowTime: 1.5
        )
        let snapshot = RunSnapshot(researchGoal: "goal", result: result)
        #expect(snapshot.researchGoal == "goal")
        #expect(snapshot.hypotheses == [h])
        #expect(snapshot.metaReviewSummary == "sum")
        #expect(snapshot.clusters.first?.clusterID == "c1")
    }

    @Test("Markdown export includes goal, hypotheses, and metrics")
    func markdownExport() {
        let md = sampleSnapshot().markdown()
        #expect(md.contains("# AI Co-Scientist — test goal"))
        #expect(md.contains("## Top hypotheses"))
        #expect(md.contains("persisted hypothesis"))
        #expect(md.contains("Elo 1275"))
        #expect(md.contains("## Metrics"))
        #expect(md.contains("reviews: 2"))
    }

    @Test("Load throws on a missing file")
    func missingFile() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("does-not-exist-\(UUID()).json")
        #expect(throws: Error.self) { _ = try RunStore.load(from: url) }
    }
}
