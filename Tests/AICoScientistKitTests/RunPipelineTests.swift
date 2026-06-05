import Testing
@testable import AICoScientistKit

@Suite("Run pipeline model")
struct RunPipelineTests {

    @Test("Seven ordered stages")
    func stages() {
        #expect(RunPipeline.stages == [
            .generation, .reflection, .ranking, .tournament, .metaReview, .evolution, .proximity])
    }

    @Test("Phase string resolves to its stage index")
    func stageIndex() {
        #expect(RunPipeline.stageIndex(forPhase: "generation") == 0)
        #expect(RunPipeline.stageIndex(forPhase: "tournament") == 3)
        #expect(RunPipeline.stageIndex(forPhase: "proximity") == 6)
    }

    @Test("Unknown / non-pipeline phases have no stage")
    func unknownPhase() {
        #expect(RunPipeline.stageIndex(forPhase: "done") == nil)
        #expect(RunPipeline.stageIndex(forPhase: "") == nil)
        #expect(RunPipeline.stageIndex(forPhase: "tool") == nil)
    }

    @Test("Display names are human-readable, including the camelCase stage")
    func displayNames() {
        #expect(RunPipeline.displayName(.metaReview) == "Meta-Review")
        #expect(RunPipeline.displayName(.generation) == "Generation")
        #expect(RunPipeline.displayName(.proximity) == "Proximity")
    }
}
