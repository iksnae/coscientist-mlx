import Testing
@testable import AICoScientistKit

@Suite("Model catalog & source policy")
struct ModelCatalogTests {

    @Test("Catalog entries are pinned to a commit (not floating main)")
    func entriesPinned() {
        #expect(!ModelCatalog.all.isEmpty)
        for model in ModelCatalog.all {
            #expect(model.revision != "main")
            #expect(model.revision.count >= 7)          // looks like a commit SHA
            #expect(model.repoID.contains("/"))
        }
    }

    @Test("Defaults exist and match the adapter defaults")
    func defaults() {
        #expect(ModelCatalog.defaultGenerator.repoID == "mlx-community/Qwen3-4B-Instruct-2507-4bit")
        #expect(ModelCatalog.defaultEmbedder.repoID == "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ")
    }

    @Test("Resolving a catalog key returns a pinned, trusted plan with no warning")
    func resolveKey() {
        let r = ModelCatalog.resolve("qwen3-4b")
        #expect(r.repoID == "mlx-community/Qwen3-4B-Instruct-2507-4bit")
        #expect(r.revision != nil)        // pinned
        #expect(r.trust == .catalog)
        #expect(r.warning == nil)
    }

    @Test("Resolving a catalog repo id also pins")
    func resolveRepoID() {
        let r = ModelCatalog.resolve("mlx-community/Qwen3-1.7B-4bit")
        #expect(r.trust == .catalog)
        #expect(r.revision != nil)
    }

    @Test("A trusted-org repo not in the catalog loads at main with a soft warning")
    func trustedOrgUnpinned() {
        let r = ModelCatalog.resolve("mlx-community/Some-New-Model-4bit")
        #expect(r.trust == .trustedOrg)
        #expect(r.revision == nil)
        #expect(r.warning?.contains("trusted org") == true)
    }

    @Test("An unknown org is flagged unverified")
    func unverified() {
        let r = ModelCatalog.resolve("randouser/sketchy-model")
        #expect(r.trust == .unverified)
        #expect(r.warning?.contains("UNVERIFIED") == true)
    }
}
