import Testing
@testable import AICoScientistKit

@Suite("Design semantics")
struct DesignSemanticsTests {

    @Test("DesignStatus label returns correct string for each case")
    func label() {
        #expect(DesignStatus.draft.label == "Draft")
        #expect(DesignStatus.running.label == "Running")
        #expect(DesignStatus.done.label == "Done")
        #expect(DesignStatus.error.label == "Error")
    }

    @Test("DesignStatus severity returns correct numeric level for each case")
    func severity() {
        #expect(DesignStatus.draft.severity == 0)
        #expect(DesignStatus.running.severity == 1)
        #expect(DesignStatus.done.severity == 2)
        #expect(DesignStatus.error.severity == 3)
    }
}
