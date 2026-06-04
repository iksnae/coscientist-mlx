import SwiftUI

@main
struct CoScientistDemoApp: App {
    var body: some Scene {
        WindowGroup("CoScientist") {
            PlaygroundView()
        }
        .defaultSize(width: 960, height: 620)

        Settings {
            SettingsView()
        }
    }
}
