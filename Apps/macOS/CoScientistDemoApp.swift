import SwiftData
import SwiftUI

@main
struct CoScientistDemoApp: App {
    var body: some Scene {
        WindowGroup("CoScientist") {
            StudiesView()
        }
        .defaultSize(width: 1040, height: 680)
        .modelContainer(StudyContainer.shared())

        Settings {
            SettingsView()
        }
    }
}
