import Testing
@testable import AICoScientistKit

@Suite("Run status text")
struct RunStatusTextTests {

    @Test("count pluralizes correctly, including the singular case")
    func count() {
        #expect(RunStatusText.count(1, "repair", "repairs") == "1 repair")
        #expect(RunStatusText.count(0, "repair", "repairs") == "0 repairs")
        #expect(RunStatusText.count(3, "hypothesis", "hypotheses") == "3 hypotheses")
    }

    @Test("finished line is plain language and correctly pluralized")
    func finished() {
        #expect(
            RunStatusText.finished(hypotheses: 3, repairs: 1, decodeFailures: 1)
                == "Done · 3 hypotheses · 1 repair · 1 decode failure")
        #expect(
            RunStatusText.finished(hypotheses: 1, repairs: 0, decodeFailures: 2)
                == "Done · 1 hypothesis · 0 repairs · 2 decode failures")
    }
}
