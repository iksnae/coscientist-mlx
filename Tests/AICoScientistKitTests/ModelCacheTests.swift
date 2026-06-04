import Foundation
import Testing
@testable import AICoScientistKit

@Suite("Model cache", .serialized)  // mutates the shared cache URL
struct ModelCacheTests {

    @Test("Maps repo id <-> HF cache directory name")
    func naming() {
        let id = "mlx-community/Qwen3-4B-Instruct-2507-4bit"
        let dir = "models--mlx-community--Qwen3-4B-Instruct-2507-4bit"
        #expect(ModelCache.directoryName(for: id) == dir)
        #expect(ModelCache.repoID(fromDirectoryName: dir) == id)   // hyphens in names survive
    }

    @Test("Detects downloaded models, sizes, and clears, in a temp cache")
    func detection() throws {
        let fm = FileManager.default
        let tmp = fm.temporaryDirectory.appendingPathComponent("hfcache-\(UUID())", isDirectory: true)
        try fm.createDirectory(at: tmp, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tmp) }

        let saved = ModelCache.huggingFaceCacheURL
        ModelCache.huggingFaceCacheURL = tmp
        defer { ModelCache.huggingFaceCacheURL = saved }

        #expect(ModelCache.isDownloaded("org/model") == false)

        let dir = ModelCache.directory(for: "org/model")
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        try Data(repeating: 7, count: 2048).write(to: dir.appendingPathComponent("weights.bin"))

        #expect(ModelCache.isDownloaded("org/model"))
        #expect(ModelCache.sizeBytes("org/model") >= 2048)
        #expect(ModelCache.downloaded().contains { $0.repoID == "org/model" })

        try ModelCache.clear("org/model")
        #expect(ModelCache.isDownloaded("org/model") == false)
    }
}
