import Foundation
import SwiftData

/// Builds the app's SwiftData container for `Study`, backed by the **CloudKit private database**
/// when iCloud is available, and falling back to a local-only store otherwise.
///
/// Local-first (a project foundation): with no iCloud account — or when the CloudKit entitlement
/// isn't provisioned (e.g. an ad-hoc/unsigned build) — the app still works fully on-device; sync
/// is additive, never required. The `Study` model is kept CloudKit-valid (M16): every attribute
/// is optional or defaulted and there are no unique constraints, so the private-DB schema loads.
enum StudyContainer {
    /// The iCloud container shared by both apps. Must match the `.entitlements` files and the
    /// container registered in the Apple Developer portal.
    static let cloudKitID = "iCloud.com.iksnae.coscientist"

    @MainActor
    static func shared() -> ModelContainer {
        let schema = Schema([Study.self])

        // 1) Preferred: CloudKit-backed private database (cross-device sync).
        let cloud = ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudKitID))
        if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
            return container
        }

        // 2) Fallback: local-only persistent store (no account / entitlement unavailable).
        let local = ModelConfiguration(schema: schema)
        if let container = try? ModelContainer(for: schema, configurations: [local]) {
            return container
        }

        // 3) Last resort: in-memory, so the app still launches instead of crashing.
        let memory = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // If even this fails the environment is fundamentally broken; a trap is acceptable here.
        return try! ModelContainer(for: schema, configurations: [memory])
    }
}
