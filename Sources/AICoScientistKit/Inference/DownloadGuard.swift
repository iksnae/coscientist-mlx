import Foundation

/// Free space on a volume. Separated from the guard so the decision logic stays pure/testable.
public enum DiskSpace {
    /// Bytes available for "important" usage (what the OS will actually let an app use) on the
    /// volume backing `url` (defaults to the home directory).
    public static func availableBytes(
        at url: URL = FileManager.default.homeDirectoryForCurrentUser
    ) -> Int64 {
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage ?? 0
    }
}

/// Decides whether a model download should proceed, given its size and free disk — so the UI
/// can disclose the size, confirm before a multi-GB pull, and block when disk is too tight
/// (which otherwise truncates the download into a corrupt model).
public enum DownloadGuard {
    /// Free space to keep in reserve beyond the model itself.
    public static let headroomBytes: Int64 = 2_000_000_000

    public enum Decision: Sendable, Equatable {
        case cached                                              // already downloaded, just load
        case proceed(downloadBytes: Int64, freeBytes: Int64)    // confirm, then download
        case insufficientDisk(neededBytes: Int64, freeBytes: Int64)
    }

    public static func decide(
        model: CatalogModel, isDownloaded: Bool, freeBytes: Int64
    ) -> Decision {
        if isDownloaded { return .cached }
        let downloadBytes = Int64(model.approxSizeGB * 1_000_000_000)
        let needed = downloadBytes + headroomBytes
        if freeBytes < needed {
            return .insufficientDisk(neededBytes: needed, freeBytes: freeBytes)
        }
        return .proceed(downloadBytes: downloadBytes, freeBytes: freeBytes)
    }

    /// Convenience: resolve a catalog key/id, then decide using the live cache + disk.
    public static func decide(forKeyOrID keyOrID: String) -> Decision {
        let resolved = ModelCatalog.resolve(keyOrID)
        guard let model = ModelCatalog.model(repoID: resolved.repoID) else {
            // Not in the catalog: no size estimate, so don't block — let it try.
            return ModelCache.isDownloaded(resolved.repoID) ? .cached
                : .proceed(downloadBytes: 0, freeBytes: DiskSpace.availableBytes())
        }
        return decide(
            model: model,
            isDownloaded: ModelCache.isDownloaded(model.repoID),
            freeBytes: DiskSpace.availableBytes())
    }
}
