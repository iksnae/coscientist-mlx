import AICoScientistKit
import Foundation
import Observation

/// Shared, persisted configuration for providers and models. Non-secrets live in
/// UserDefaults; secrets (API key, HF token) live in the Keychain. The HF token is exported
/// to the environment so the Hugging Face downloader picks it up for gated repos.
@MainActor
@Observable
final class SettingsStore {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    var generatorKey: String { didSet { defaults.set(generatorKey, forKey: "generatorKey") } }
    var embedderKey: String { didSet { defaults.set(embedderKey, forKey: "embedderKey") } }
    var remoteEnabled: Bool { didSet { defaults.set(remoteEnabled, forKey: "remoteEnabled") } }
    var remoteBaseURL: String { didSet { defaults.set(remoteBaseURL, forKey: "remoteBaseURL") } }
    var remoteModel: String { didSet { defaults.set(remoteModel, forKey: "remoteModel") } }

    var openAIKey: String { didSet { Keychain.set(openAIKey, for: "openai") } }
    var hfToken: String {
        didSet {
            Keychain.set(hfToken, for: "huggingface")
            applyHFToken()
        }
    }

    /// Whether a usable remote judge is configured.
    var remoteReady: Bool { remoteEnabled && !openAIKey.isEmpty && !remoteModel.isEmpty }

    private init() {
        generatorKey = defaults.string(forKey: "generatorKey") ?? ModelCatalog.defaultGeneratorKey
        embedderKey = defaults.string(forKey: "embedderKey") ?? ModelCatalog.defaultEmbedderKey
        remoteEnabled = defaults.bool(forKey: "remoteEnabled")
        remoteBaseURL = defaults.string(forKey: "remoteBaseURL") ?? "https://api.openai.com/v1"
        remoteModel = defaults.string(forKey: "remoteModel") ?? "gpt-4o"
        openAIKey = Keychain.get("openai")
        hfToken = Keychain.get("huggingface")
        applyHFToken()
    }

    /// Export the HF token so swift-transformers' Hub uses it (for gated/private repos).
    func applyHFToken() {
        guard !hfToken.isEmpty else { return }
        setenv("HF_TOKEN", hfToken, 1)
        setenv("HUGGING_FACE_HUB_TOKEN", hfToken, 1)
    }
}
