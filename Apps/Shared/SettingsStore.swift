import AICoScientistFoundationModels
import AICoScientistKit
import AICoScientistRemote
import Foundation
import Observation

/// Shared, persisted configuration for providers and models, stored in UserDefaults.
///
/// Note: the API key and HF token are stored in UserDefaults (plaintext in the app's
/// preferences), not the Keychain. This is a deliberate trade-off for this local,
/// unsandboxed, ad-hoc-signed demo: the legacy Keychain prompts for access on every launch
/// when the binary has no stable code-signing identity. The HF token is exported to the
/// environment so the Hugging Face downloader picks it up for gated repos.
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var generatorKey: String { didSet { defaults.set(generatorKey, forKey: "generatorKey") } }
    var embedderKey: String { didSet { defaults.set(embedderKey, forKey: "embedderKey") } }
    /// Generator backend: MLX (default) or Apple Foundation Models (where available).
    var backend: InferenceBackend { didSet { defaults.set(backend.rawValue, forKey: "backend") } }
    var remoteEnabled: Bool { didSet { defaults.set(remoteEnabled, forKey: "remoteEnabled") } }
    var remoteBaseURL: String { didSet { defaults.set(remoteBaseURL, forKey: "remoteBaseURL") } }
    var remoteModel: String { didSet { defaults.set(remoteModel, forKey: "remoteModel") } }

    /// Per-role hosted-model assignments (role rawValue → model id). A role absent here runs
    /// on the local model. Persisted as a plist dictionary.
    var agentModels: [String: String] { didSet { defaults.set(agentModels, forKey: "agentModels") } }

    /// Models discovered from the provider (`RemoteModels.list`), in-memory only.
    var fetchedModels: [String] = []
    var isFetchingModels = false
    var modelsError: String?

    var openAIKey: String { didSet { defaults.set(openAIKey, forKey: "openAIKey") } }
    var hfToken: String {
        didSet {
            defaults.set(hfToken, forKey: "hfToken")
            applyHFToken()
        }
    }

    /// Whether a usable remote judge is configured.
    var remoteReady: Bool { remoteEnabled && !openAIKey.isEmpty && !remoteModel.isEmpty }

    /// Whether Apple Foundation Models is usable on this device right now.
    var foundationAvailable: Bool { FoundationModelsBackend.isAvailable }

    private init() {
        generatorKey = defaults.string(forKey: "generatorKey") ?? ModelCatalog.defaultGeneratorKey
        embedderKey = defaults.string(forKey: "embedderKey") ?? ModelCatalog.defaultEmbedderKey
        backend = InferenceBackend(rawValue: defaults.string(forKey: "backend") ?? "") ?? .mlx
        agentModels = defaults.dictionary(forKey: "agentModels") as? [String: String] ?? [:]
        remoteEnabled = defaults.bool(forKey: "remoteEnabled")
        remoteBaseURL = defaults.string(forKey: "remoteBaseURL") ?? "https://api.openai.com/v1"
        remoteModel = defaults.string(forKey: "remoteModel") ?? "gpt-4o"
        openAIKey = defaults.string(forKey: "openAIKey") ?? ""
        hfToken = defaults.string(forKey: "hfToken") ?? ""
        applyHFToken()
    }

    /// Per-role backends for the engine. Only when a remote is usable; otherwise empty so
    /// every role stays local (local-first).
    var roleBackends: [AgentRole: RoleBackend] {
        guard remoteReady else { return [:] }
        var result: [AgentRole: RoleBackend] = [:]
        for (raw, id) in agentModels {
            if let role = AgentRole(rawValue: raw), !id.isEmpty { result[role] = .remote(id) }
        }
        return result
    }

    /// Assign (or clear, with nil) a hosted model for one role.
    func assign(_ role: AgentRole, to id: String?) {
        if let id, !id.isEmpty { agentModels[role.rawValue] = id }
        else { agentModels.removeValue(forKey: role.rawValue) }
    }

    /// One-tap backing presets over the configured `remoteModel`.
    enum BackingPreset { case allLocal, hostedJudge, hostedAll }
    func applyPreset(_ preset: BackingPreset) {
        switch preset {
        case .allLocal:
            agentModels = [:]
        case .hostedJudge:
            agentModels = [
                AgentRole.reflection.rawValue: remoteModel,
                AgentRole.tournament.rawValue: remoteModel,
            ]
        case .hostedAll:
            agentModels = Dictionary(
                uniqueKeysWithValues: AgentRole.allCases.map { ($0.rawValue, remoteModel) })
        }
    }

    /// Fetch the provider's model list into `fetchedModels` (for the pickers).
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
