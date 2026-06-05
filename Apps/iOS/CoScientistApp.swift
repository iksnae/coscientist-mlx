import SwiftData
import SwiftUI

@main
struct CoScientistApp: App {
    var body: some Scene {
        WindowGroup {
            StudiesView()
        }
        .modelContainer(StudyContainer.shared())
    }
}
