import Foundation

/// Inspects the local Hugging Face model cache — to tell whether a model is already
/// downloaded (so the UI can skip the "download" disclosure), report sizes, and clear models
/// to reclaim disk. Pure Foundation; `huggingFaceCacheURL` is overridable for tests.
public enum ModelCache {
    /// The HF Hub cache root (`<userBase>/.cache/huggingface/hub` — home on macOS, app docs on
    /// iOS). Overridable in tests.
    public nonisolated(unsafe) static var huggingFaceCacheURL: URL =
        PlatformPaths.userBase
        .appendingPathComponent(".cache/huggingface/hub", isDirectory: true)

    public struct DownloadedModel: Sendable, Equatable {
        public let repoID: String
        public let bytes: Int64
    }

    /// HF encodes a repo id `org/name` as the directory `models--org--name`.
    public static func directoryName(for repoID: String) -> String {
        "models--" + repoID.replacingOccurrences(of: "/", with: "--")
    }

    public static func repoID(fromDirectoryName name: String) -> String {
        name.replacingOccurrences(of: "models--", with: "")
            .replacingOccurrences(of: "--", with: "/")
    }

    public static func directory(for repoID: String) -> URL {
        huggingFaceCacheURL.appendingPathComponent(directoryName(for: repoID), isDirectory: true)
    }

    public static func isDownloaded(_ repoID: String) -> Bool {
        FileManager.default.fileExists(atPath: directory(for: repoID).path)
    }

    public static func sizeBytes(_ repoID: String) -> Int64 { folderSize(directory(for: repoID)) }

    public static func totalBytes() -> Int64 { folderSize(huggingFaceCacheURL) }

    public static func downloaded() -> [DownloadedModel] {
        let fm = FileManager.default
        guard
            let entries = try? fm.contentsOfDirectory(
                at: huggingFaceCacheURL, includingPropertiesForKeys: nil)
        else { return [] }
        return entries
            .filter { $0.lastPathComponent.hasPrefix("models--") }
            .map { DownloadedModel(repoID: repoID(fromDirectoryName: $0.lastPathComponent), bytes: folderSize($0)) }
            .sorted { $0.bytes > $1.bytes }
    }

    public static func clear(_ repoID: String) throws {
        try FileManager.default.removeItem(at: directory(for: repoID))
    }

    static func folderSize(_ url: URL) -> Int64 {
        let fm = FileManager.default
        guard
            let enumerator = fm.enumerator(
                at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
        else { return 0 }
        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileSizeKey])
            total += Int64(values?.totalFileAllocatedSize ?? values?.fileSize ?? 0)
        }
        return total
    }
}
