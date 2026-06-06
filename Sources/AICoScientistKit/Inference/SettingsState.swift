import Foundation

/// Pure, reduced settings for the hosted provider + on-device embedder (M22). The app's
/// `SettingsStore` projects this and runs persistence (UserDefaults) + HF env as side-effects;
/// the transitions + derived values live here so they're unit-tested.
public struct SettingsState: StateType, Equatable {
    public var embedderKey: String
    public var remoteBaseURL: String
    public var remoteModel: String
    public var openAIKey: String
    public var hfToken: String
    public var fetchedModels: [String]

    public init(
        embedderKey: String = "",
        remoteBaseURL: String = "https://api.openai.com/v1",
        remoteModel: String = "gpt-4o",
        openAIKey: String = "",
        hfToken: String = "",
        fetchedModels: [String] = []
    ) {
        self.embedderKey = embedderKey
        self.remoteBaseURL = remoteBaseURL
        self.remoteModel = remoteModel
        self.openAIKey = openAIKey
        self.hfToken = hfToken
        self.fetchedModels = fetchedModels
    }

    /// A usable hosted provider needs a base URL, an API key, and a model.
    public var remoteReady: Bool {
        !openAIKey.isEmpty && !remoteModel.isEmpty && URL(string: remoteBaseURL) != nil
    }

    /// Hosted model ids for the pickers — configured-first, de-duplicated, ready-gated.
    public var hostedModelOptions: [String] {
        HostedModels.options(ready: remoteReady, configured: remoteModel, fetched: fetchedModels)
    }
}

public enum SettingsAction: ActionType {
    case setEmbedder(String)
    case setBaseURL(String)
    case setModel(String)
    case setKey(String)
    case setToken(String)
    case setFetchedModels([String])
}

/// Pure settings reducer. Changing the API key or base URL invalidates the cached model list
/// (it belongs to the previous provider); changing the model does not.
public func settingsReducer(_ state: SettingsState, _ action: any ActionType) -> SettingsState {
    guard let action = action as? SettingsAction else { return state }
    var s = state
    switch action {
    case .setEmbedder(let v): s.embedderKey = v
    case .setBaseURL(let v): s.remoteBaseURL = v; s.fetchedModels = []
    case .setModel(let v): s.remoteModel = v
    case .setKey(let v): s.openAIKey = v; s.fetchedModels = []
    case .setToken(let v): s.hfToken = v
    case .setFetchedModels(let v): s.fetchedModels = v
    }
    return s
}
