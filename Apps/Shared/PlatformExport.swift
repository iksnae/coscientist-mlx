import SwiftUI

#if os(macOS)
    import AppKit
#else
    import UIKit
#endif

/// Cross-platform "export a file": a save panel on macOS, the share sheet on iOS. The caller
/// supplies a `write` closure that serializes to a URL; on macOS the user picks the location,
/// on iOS the file is written to a temp URL and handed to `UIActivityViewController`.
enum PlatformExport {
    @MainActor
    static func save(suggestedName: String, write: (URL) throws -> Void) {
        #if os(macOS)
            let panel = NSSavePanel()
            panel.nameFieldStringValue = suggestedName
            panel.canCreateDirectories = true
            guard panel.runModal() == .OK, let url = panel.url else { return }
            try? write(url)
        #else
            let url = FileManager.default.temporaryDirectory.appendingPathComponent(suggestedName)
            do { try write(url) } catch { return }
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            guard
                let scene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene }).first,
                let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            else { return }
            // iPad requires a popover anchor.
            activity.popoverPresentationController?.sourceView = root.view
            activity.popoverPresentationController?.sourceRect = CGRect(
                x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            root.present(activity, animated: true)
        #endif
    }
}
