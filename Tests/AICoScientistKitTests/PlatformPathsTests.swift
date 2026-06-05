import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Platform paths")
struct PlatformPathsTests {
    @Test("userBase is a file URL with a non-empty path")
    func userBase() {
        let base = PlatformPaths.userBase
        #expect(base.isFileURL)
        #expect(!base.path.isEmpty)
    }
}
