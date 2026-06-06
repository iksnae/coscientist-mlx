import Testing
@testable import AICoScientistKit

@Suite("Study title logic")
struct StudyTitleTests {

    @Test("A non-empty, goal-divergent edit is custom; matching or empty edits are not")
    func isCustom() {
        #expect(StudyTitle.isCustom(editedTitle: "My study", goal: "Coffee benefits"))
        #expect(!StudyTitle.isCustom(editedTitle: "Coffee benefits", goal: "Coffee benefits"))
        // Empty / whitespace title is NOT custom — it resumes tracking the goal (fixes the
        // "Untitled study" stuck state).
        #expect(!StudyTitle.isCustom(editedTitle: "", goal: "Coffee benefits"))
        #expect(!StudyTitle.isCustom(editedTitle: "   ", goal: "Coffee benefits"))
    }

    @Test("Display falls back to the goal's first line, then a generic placeholder")
    func display() {
        #expect(StudyTitle.display(title: "Custom", goal: "x") == "Custom")
        #expect(StudyTitle.display(title: "", goal: "Coffee benefits\nmore") == "Coffee benefits")
        #expect(StudyTitle.display(title: "   ", goal: "Coffee benefits") == "Coffee benefits")
        #expect(StudyTitle.display(title: "", goal: "") == "Untitled study")
    }
}
