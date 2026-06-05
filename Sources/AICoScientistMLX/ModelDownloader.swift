import AICoScientistKit
import Foundation

/// Downloads + caches a catalog model on demand (for offline use), without keeping it resident.
///
/// Loading a model fetches its files into the Hugging Face cache; we load then immediately
/// release, so the files stay cached for later runs while memory is freed. This reuses the exact
/// download path real runs use, so a model that downloads here will load identically at run time.
public enum ModelDownloader {
    /// Download + cache the catalog model with `key` (generator or embedder), reporting progress
    /// 0…1. Throws if the fetch fails (e.g. offline, gated repo without a token, out of disk).
    public static func download(
        _ key: String, onProgress: (@Sendable (Double) -> Void)? = nil
    ) async throws {
        if ModelCatalog.embedders.contains(where: { $0.key == key }) {
            _ = try await MLXEmbeddingModel.load(key, onProgress: onProgress)
        } else {
            _ = try await MLXLanguageModel.load(key, onProgress: onProgress)
        }
    }
}
