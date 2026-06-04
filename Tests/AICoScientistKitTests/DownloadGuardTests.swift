import Testing
@testable import AICoScientistKit

@Suite("Download guard")
struct DownloadGuardTests {
    private let model = ModelCatalog.model(key: "qwen3-8b")!   // ~4.6 GB

    @Test("Already downloaded → just load")
    func cached() {
        #expect(DownloadGuard.decide(model: model, isDownloaded: true, freeBytes: 1_000) == .cached)
    }

    @Test("Enough disk → proceed with the disclosed size")
    func proceed() {
        let decision = DownloadGuard.decide(
            model: model, isDownloaded: false, freeBytes: 50_000_000_000)
        guard case let .proceed(downloadBytes, _) = decision else {
            Issue.record("expected proceed, got \(decision)"); return
        }
        #expect(downloadBytes > 4_000_000_000)
    }

    @Test("Tight disk → block before truncating the download")
    func insufficient() {
        // 5 GB free can't fit a ~4.6 GB model plus 2 GB headroom.
        let decision = DownloadGuard.decide(
            model: model, isDownloaded: false, freeBytes: 5_000_000_000)
        guard case let .insufficientDisk(needed, free) = decision else {
            Issue.record("expected insufficientDisk, got \(decision)"); return
        }
        #expect(needed > free)
    }
}
