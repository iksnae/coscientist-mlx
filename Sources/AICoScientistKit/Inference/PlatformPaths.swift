import Foundation

/// Cross-platform filesystem bases. `homeDirectoryForCurrentUser` is macOS-only; iOS apps are
/// sandboxed and have no user home, so fall back to the app's documents directory.
public enum PlatformPaths {
    /// A per-user base directory: the home directory on macOS, the app's documents directory
    /// on iOS/other platforms.
    public static var userBase: URL {
        #if os(macOS)
            return FileManager.default.homeDirectoryForCurrentUser
        #else
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
        #endif
    }
}
