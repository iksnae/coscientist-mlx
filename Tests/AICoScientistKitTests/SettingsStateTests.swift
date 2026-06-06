import Testing
@testable import AICoScientistKit

@Suite("Settings state reducer")
struct SettingsStateTests {

    @Test("Changing the API key or base URL invalidates the cached model list")
    func providerChangeClearsCache() {
        var s = SettingsState()
        s.fetchedModels = ["a", "b"]
        s = settingsReducer(s, SettingsAction.setKey("sk-1"))
        #expect(s.openAIKey == "sk-1")
        #expect(s.fetchedModels.isEmpty)

        s.fetchedModels = ["a"]
        s = settingsReducer(s, SettingsAction.setBaseURL("https://x/v1"))
        #expect(s.fetchedModels.isEmpty)
    }

    @Test("Changing the model does NOT clear the cached list")
    func modelChangeKeepsCache() {
        var s = SettingsState()
        s.fetchedModels = ["a", "b"]
        s = settingsReducer(s, SettingsAction.setModel("gpt-4o"))
        #expect(s.remoteModel == "gpt-4o")
        #expect(s.fetchedModels == ["a", "b"])
    }

    @Test("remoteReady requires key + model + valid base URL")
    func ready() {
        var s = SettingsState(remoteBaseURL: "https://api.openai.com/v1", remoteModel: "gpt-4o")
        #expect(!s.remoteReady)            // no key
        s = settingsReducer(s, SettingsAction.setKey("sk"))
        #expect(s.remoteReady)
    }

    @Test("hostedModelOptions delegates to the resolver (configured-first, gated)")
    func hostedOptions() {
        var s = SettingsState(remoteBaseURL: "https://api.openai.com/v1", remoteModel: "gpt-4o")
        #expect(s.hostedModelOptions.isEmpty)            // not ready
        s = settingsReducer(s, SettingsAction.setKey("sk"))
        s = settingsReducer(s, SettingsAction.setFetchedModels(["gpt-4o-mini", "gpt-4o"]))
        #expect(s.hostedModelOptions == ["gpt-4o", "gpt-4o-mini"])
    }
}
