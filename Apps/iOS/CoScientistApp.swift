import SwiftData
import SwiftUI

@main
struct CoScientistApp: App {
    var body: some Scene {
        WindowGroup {
            StudiesView()
        }
        .modelContainer(for: Study.self)
    }
}
