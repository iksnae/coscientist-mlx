import Testing
@testable import AICoScientistKit

@Suite("Hosted model options resolver")
struct HostedModelsTests {

    @Test("Not ready → no hosted options")
    func notReady() {
        #expect(HostedModels.options(ready: false, configured: "gpt-4o", fetched: ["a"]).isEmpty)
    }

    @Test("Ready with no fetched list still offers the configured model")
    func configuredOnly() {
        #expect(HostedModels.options(ready: true, configured: "gpt-4o", fetched: []) == ["gpt-4o"])
    }

    @Test("Configured model leads, then fetched, deduped")
    func mergedDeduped() {
        let opts = HostedModels.options(
            ready: true, configured: "gpt-4o", fetched: ["gpt-4o-mini", "gpt-4o", "o3"])
        #expect(opts == ["gpt-4o", "gpt-4o-mini", "o3"])
    }

    @Test("No configured model → just the fetched list, order preserved + deduped")
    func fetchedOnly() {
        let opts = HostedModels.options(
            ready: true, configured: "", fetched: ["a", "b", "a"])
        #expect(opts == ["a", "b"])
    }

    @Test("Whitespace-only configured model is ignored")
    func blankConfigured() {
        #expect(HostedModels.options(ready: true, configured: "  ", fetched: ["a"]) == ["a"])
    }
}
