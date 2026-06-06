import AICoScientistFoundationModels
import AICoScientistKit
import AICoScientistRemote
import Foundation
import Observation

/// Shared configuration for the hosted provider + on-device embedder. State is a reduced
/// `SettingsState` (M22): field transitions go through `settingsReducer` (pure, tested); this
/// store runs the side-effects — UserDefaults persistence, the HF env (`HF_HUB_CACHE`, token),
/// and the model-list fetch. The computed accessors keep the same names so views/bindings are
/// unchanged.
///
/// Per-study model selection (Generator/Reviewer) lives on the `Study` via `ModelChoice`; this
/// store no longer carries the legacy global generator/backend/per-agent state (removed in M20).
///
/// Note: the API key and HF token are stored in UserDefaults (plaintext app preferences), a
/// deliberate trade-off for this local, unsandboxed, ad-hoc-signed demo.
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private(set) var state: SettingsState

    var isFetchingModels = false
    var modelsError: String?
    private var autoLoadAttempted = false

    private init() {
        state = SettingsState(
            embedderKey: defaults.string(forKey: "embedderKey") ?? ModelCatalog.defaultEmbedderKey,
            remoteBaseURL: defaults.string(forKey: "remoteBaseURL") ?? "https://api.openai.com/v1",
            remoteModel: defaults.string(forKey: "remoteModel") ?? "gpt-4o",
            openAIKey: defaults.string(forKey: "openAIKey") ?? "",
            hfToken: defaults.string(forKey: "hfToken") ?? "",
            fetchedModels: defaults.stringArray(forKey: "fetchedModels") ?? [])
        migrateRemovingDeadKeys()
        applyHFToken()
        applyModelCacheLocation()
    }

    private func apply(_ action: SettingsAction) { state = settingsReducer(state, action) }

    // Bindable projections (same names as before); setters dispatch + persist.
    var embedderKey: String {
        get { state.embedderKey }
        set { apply(.setEmbedder(newValue)); defaults.set(newValue, forKey: "embedderKey") }
    }
    var remoteBaseURL: String {
        get { state.remoteBaseURL }
        set { apply(.setBaseURL(newValue)); persistProvider() }
    }
    var remoteModel: String {
        get { state.remoteModel }
        set { apply(.setModel(newValue)); defaults.set(newValue, forKey: "remoteModel") }
    }
    var openAIKey: String {
        get { state.openAIKey }
        set { apply(.setKey(newValue)); persistProvider() }
    }
    var hfToken: String {
        get { state.hfToken }
        set {
            apply(.setToken(newValue))
            defaults.set(newValue, forKey: "hfToken")
            applyHFToken()
        }
    }
    var fetchedModels: [String] {
        get { state.fetchedModels }
        set { apply(.setFetchedModels(newValue)); defaults.set(newValue, forKey: "fetchedModels") }
    }

    /// After a key/base-URL change (which the reducer treats as a provider change and clears the
    /// cached list), persist the provider fields + the cleared cache and allow a re-fetch.
    private func persistProvider() {
        defaults.set(state.remoteBaseURL, forKey: "remoteBaseURL")
        defaults.set(state.openAIKey, forKey: "openAIKey")
        defaults.set(state.fetchedModels, forKey: "fetchedModels")
        autoLoadAttempted = false
        modelsError = nil
    }

    var remoteReady: Bool { state.remoteReady }
    var foundationAvailable: Bool { FoundationModelsBackend.isAvailable }
    var hostedModelOptions: [String] { state.hostedModelOptions }

    /// Background-load the provider's model list once, when ready and not yet loaded.
    func ensureModelsLoaded() async {
        guard state.remoteReady, state.fetchedModels.isEmpty, !isFetchingModels, !autoLoadAttempted
        else { return }
        autoLoadAttempted = true
        await refreshModels()
    }

    /// Fetch the provider's model list into `fetchedModels` (also caches it).
    func refreshModels() async {
        guard let url = URL(string: state.remoteBaseURL), !state.openAIKey.isEmpty else {
            modelsError = "Set the base URL and API key first."
            return
        }
        isFetchingModels = true
        modelsError = nil
        defer { isFetchingModels = false }
        do { fetchedModels = try await RemoteModels.list(baseURL: url, apiKey: state.openAIKey) }
        catch { modelsError = "\(error)" }
    }

    /// One-time cleanup of UserDefaults keys for state removed in M20.
    private func migrateRemovingDeadKeys() {
        for key in ["generatorKey", "backend", "agentModels", "roleBackends", "remoteEnabled"] {
            defaults.removeObject(forKey: key)
        }
    }

    /// Export the HF token so swift-transformers' Hub uses it (for gated/private repos).
    func applyHFToken() {
        guard !state.hfToken.isEmpty else { return }
        setenv("HF_TOKEN", state.hfToken, 1)
        setenv("HUGGING_FACE_HUB_TOKEN", state.hfToken, 1)
    }

    /// Point the HF downloader at the directory `ModelCache` inspects (so cached models are
    /// detected on every platform; see M20). `HF_HUB_CACHE` is the downloader's #1 setting.
    private func applyModelCacheLocation() {
        setenv("HF_HUB_CACHE", ModelCache.huggingFaceCacheURL.path, 1)
    }
}
