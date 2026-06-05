import AICoScientistFoundationModels
import AICoScientistKit
import AICoScientistRemote
import Foundation
import Observation

/// Shared, persisted configuration for the hosted provider and the on-device embedder, stored in
/// UserDefaults.
///
/// Per-study model selection (Generator/Reviewer) lives on the `Study` as `ModelChoice` and is
/// routed by `StudyRouting`; this store no longer carries the legacy global generator/backend/
/// per-agent-backing state (removed in M20).
///
/// Note: the API key and HF token are stored in UserDefaults (plaintext in the app's
/// preferences), not the Keychain — a deliberate trade-off for this local, unsandboxed,
/// ad-hoc-signed demo (the legacy Keychain prompts for access on every launch when the binary
/// has no stable code-signing identity). The HF token is exported to the environment so the
/// Hugging Face downloader picks it up for gated repos.
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    /// Gates didSet side-effects during init (so loading the cache isn't clobbered).
    private var booted = false

    var embedderKey: String { didSet { defaults.set(embedderKey, forKey: "embedderKey") } }
    var remoteBaseURL: String {
        didSet { defaults.set(remoteBaseURL, forKey: "remoteBaseURL"); invalidateModelCache() }
    }
    var remoteModel: String { didSet { defaults.set(remoteModel, forKey: "remoteModel") } }

    var openAIKey: String {
        didSet { defaults.set(openAIKey, forKey: "openAIKey"); invalidateModelCache() }
    }
    var hfToken: String {
        didSet {
            defaults.set(hfToken, forKey: "hfToken")
            applyHFToken()
        }
    }

    /// Models discovered from the provider (`RemoteModels.list`), cached across launches so the
    /// pickers populate immediately without a manual refresh.
    var fetchedModels: [String] = [] {
        didSet { defaults.set(fetchedModels, forKey: "fetchedModels") }
    }
    var isFetchingModels = false
    var modelsError: String?
    private var autoLoadAttempted = false

    /// Whether a usable hosted provider is configured (base URL + key + model present).
    var remoteReady: Bool {
        !openAIKey.isEmpty && !remoteModel.isEmpty && URL(string: remoteBaseURL) != nil
    }

    /// Whether Apple Foundation Models is usable on this device right now.
    var foundationAvailable: Bool { FoundationModelsBackend.isAvailable }

    /// Hosted model ids for the pickers — configured-first, de-duplicated, ready-gated.
    var hostedModelOptions: [String] {
        HostedModels.options(ready: remoteReady, configured: remoteModel, fetched: fetchedModels)
    }

    private init() {
        embedderKey = defaults.string(forKey: "embedderKey") ?? ModelCatalog.defaultEmbedderKey
        remoteBaseURL = defaults.string(forKey: "remoteBaseURL") ?? "https://api.openai.com/v1"
        remoteModel = defaults.string(forKey: "remoteModel") ?? "gpt-4o"
        openAIKey = defaults.string(forKey: "openAIKey") ?? ""
        hfToken = defaults.string(forKey: "hfToken") ?? ""
        fetchedModels = defaults.stringArray(forKey: "fetchedModels") ?? []
        migrateRemovingDeadKeys()
        applyHFToken()
        applyModelCacheLocation()
        booted = true
    }

    /// Point the Hugging Face downloader at the exact directory `ModelCache` inspects, so a
    /// downloaded model is detected as cached on every platform. `HF_HUB_CACHE` is the
    /// downloader's highest-priority cache setting; without this, the library's default sandbox
    /// location on iOS differs from `ModelCache`'s path, so every run wrongly re-prompts to
    /// download. (On macOS this resolves to the same `~/.cache/huggingface/hub`, so nothing
    /// changes and existing downloads stay found.)
    private func applyModelCacheLocation() {
        setenv("HF_HUB_CACHE", ModelCache.huggingFaceCacheURL.path, 1)
    }

    /// One-time cleanup of UserDefaults keys for state removed in M20 (legacy global generator,
    /// backend, per-agent backings, the hosted-enable toggle) so stale values don't linger.
    private func migrateRemovingDeadKeys() {
        for key in ["generatorKey", "backend", "agentModels", "roleBackends", "remoteEnabled"] {
            defaults.removeObject(forKey: key)
        }
    }

    /// Provider identity changed → drop the cached list so it re-loads for the new provider.
    private func invalidateModelCache() {
        guard booted else { return }
        fetchedModels = []
        modelsError = nil
        autoLoadAttempted = false
    }

    /// Background-load the provider's model list once, when ready and not yet loaded. Safe to
    /// call from a view `.task`; it no-ops if a cache exists, a fetch is in flight, or already
    /// attempted for the current provider.
    func ensureModelsLoaded() async {
        guard remoteReady, fetchedModels.isEmpty, !isFetchingModels, !autoLoadAttempted else { return }
        autoLoadAttempted = true
        await refreshModels()
    }

    /// Fetch the provider's model list into `fetchedModels` (also caches it).
    func refreshModels() async {
        guard let url = URL(string: remoteBaseURL), !openAIKey.isEmpty else {
            modelsError = "Set the base URL and API key first."
            return
        }
        isFetchingModels = true
        modelsError = nil
        defer { isFetchingModels = false }
        do { fetchedModels = try await RemoteModels.list(baseURL: url, apiKey: openAIKey) }
        catch { modelsError = "\(error)" }
    }

    /// Export the HF token so swift-transformers' Hub uses it (for gated/private repos).
    func applyHFToken() {
        guard !hfToken.isEmpty else { return }
        setenv("HF_TOKEN", hfToken, 1)
        setenv("HUGGING_FACE_HUB_TOKEN", hfToken, 1)
    }
}
