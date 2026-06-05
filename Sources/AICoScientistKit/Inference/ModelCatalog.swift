/// Whether a model generates text or produces embeddings.
public enum ModelRole: String, Sendable, CaseIterable, Codable {
    case generator
    case embedder
}

/// A vetted model entry: a Hugging Face repo pinned to a specific commit, with metadata for
/// selection. Pinning the `revision` (not floating `main`) makes loads content-stable and is
/// the project's supply-chain safeguard.
public struct CatalogModel: Sendable, Identifiable, Equatable, Codable {
    public var id: String { key }
    public let key: String              // short selector, e.g. "qwen3-4b"
    public let repoID: String           // Hugging Face repo id
    public let revision: String         // pinned commit SHA
    public let displayName: String
    public let approxSizeGB: Double
    public let minRAMGB: Int
    public let role: ModelRole
    /// Capability tier from `docs/MODELS.md` (e.g. "Small", "Mid", "Large", "Embedder").
    public let tier: String
    /// One-line strengths/why, from the `docs/MODELS.md` research.
    public let strengths: String

    public init(
        key: String, repoID: String, revision: String, displayName: String,
        approxSizeGB: Double, minRAMGB: Int, role: ModelRole,
        tier: String = "", strengths: String = ""
    ) {
        self.key = key
        self.repoID = repoID
        self.revision = revision
        self.displayName = displayName
        self.approxSizeGB = approxSizeGB
        self.minRAMGB = minRAMGB
        self.role = role
        self.tier = tier
        self.strengths = strengths
    }

    /// Decode tolerantly: `tier`/`strengths` were added in M13, so older encodings omit them.
    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        key = try c.decode(String.self, forKey: .key)
        repoID = try c.decode(String.self, forKey: .repoID)
        revision = try c.decode(String.self, forKey: .revision)
        displayName = try c.decode(String.self, forKey: .displayName)
        approxSizeGB = try c.decode(Double.self, forKey: .approxSizeGB)
        minRAMGB = try c.decode(Int.self, forKey: .minRAMGB)
        role = try c.decode(ModelRole.self, forKey: .role)
        tier = try c.decodeIfPresent(String.self, forKey: .tier) ?? ""
        strengths = try c.decodeIfPresent(String.self, forKey: .strengths) ?? ""
    }
}

/// How well a model fits a device's RAM.
public enum ModelFit: String, Sendable, Equatable {
    case insufficient   // device RAM below the model's minimum
    case tight          // meets the minimum, little headroom
    case comfortable    // comfortable headroom
}

extension CatalogModel {
    /// Compatibility of this model with a device that has `deviceRAMGB` of RAM. Pure so the
    /// app can feed `ProcessInfo.physicalMemory` and the logic stays unit-testable.
    public func fit(deviceRAMGB: Int) -> ModelFit {
        if deviceRAMGB < minRAMGB { return .insufficient }
        if deviceRAMGB < minRAMGB + (minRAMGB / 2) { return .tight }
        return .comfortable
    }
}

/// How a requested model resolved, and how much to trust it.
public struct ResolvedModel: Sendable, Equatable {
    public enum Trust: Sendable, Equatable {
        case catalog      // a curated, pinned entry
        case trustedOrg   // not in the catalog, but from a trusted org (loaded at `main`)
        case unverified   // unknown org — load only if the user trusts it
    }

    public let repoID: String
    /// Pinned commit, or `nil` to track `main`.
    public let revision: String?
    public let trust: Trust

    public init(repoID: String, revision: String?, trust: Trust) {
        self.repoID = repoID
        self.revision = revision
        self.trust = trust
    }

    /// A warning to surface before loading, or `nil` when fully vetted.
    public var warning: String? {
        switch trust {
        case .catalog:
            return nil
        case .trustedOrg:
            return "Model '\(repoID)' is from a trusted org but not in the curated catalog; "
                + "loading at 'main' (unpinned)."
        case .unverified:
            return "⚠️ Model '\(repoID)' is from an UNVERIFIED source (not a trusted org); "
                + "loading at 'main' (unpinned). Proceed only if you trust this repository."
        }
    }
}

/// The curated, pinned set of models the project ships, plus the source-trust policy.
/// Single source of truth for selection (CLI/app) — mirrors `docs/MODELS.md`.
public enum ModelCatalog {
    /// Orgs whose models are allowed without an "unverified" warning (still unpinned unless
    /// in the catalog). Drawn from docs/MODELS.md.
    public static let trustedOrgs: Set<String> = [
        "mlx-community", "BAAI", "nomic-ai", "sentence-transformers",
        "Snowflake", "LiquidAI", "intfloat", "mixedbread-ai",
    ]

    public static let generators: [CatalogModel] = [
        CatalogModel(
            key: "qwen3-4b", repoID: "mlx-community/Qwen3-4B-Instruct-2507-4bit",
            revision: "50d427756c6b1b2fe0c0a10f67fbda1fc8e82c1b",
            displayName: "Qwen3-4B Instruct (4-bit)", approxSizeGB: 2.3, minRAMGB: 8,
            role: .generator, tier: "Small",
            strengths: "Smaller and smarter than the 7B default; instruct (no <think>) gives the cleanest JSON for judge/scorer roles."),
        CatalogModel(
            key: "qwen3-1.7b", repoID: "mlx-community/Qwen3-1.7B-4bit",
            revision: "3b1b1768f8f8cf8351c712464f906e86c2b8269e",
            displayName: "Qwen3-1.7B (4-bit)", approxSizeGB: 1.0, minRAMGB: 8, role: .generator,
            tier: "Small",
            strengths: "Fast, cheap judge for the tournament fan-out; adds a reasoning mode."),
        CatalogModel(
            key: "qwen3-8b", repoID: "mlx-community/Qwen3-8B-4bit-DWQ",
            revision: "abdc7a619e12b13119e292c889ebf8e90f4ef592",
            displayName: "Qwen3-8B (4-bit DWQ)", approxSizeGB: 4.6, minRAMGB: 16, role: .generator,
            tier: "Mid",
            strengths: "Hybrid reasoning on the plain LLM path; the strongest safe pick when RAM allows."),
        CatalogModel(
            key: "llama3.2-3b", repoID: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            revision: "7f0dc925e0d0afb0322d96f9255cfddf2ba5636e",
            displayName: "Llama-3.2-3B Instruct (4-bit)", approxSizeGB: 1.8, minRAMGB: 8,
            role: .generator, tier: "Small",
            strengths: "Compact Llama instruct; light, quick generation."),
        CatalogModel(
            key: "llama3.2-1b", repoID: "mlx-community/Llama-3.2-1B-Instruct-4bit",
            revision: "08231374eeacb049a0eade7922910865b8fce912",
            displayName: "Llama-3.2-1B Instruct (4-bit)", approxSizeGB: 0.7, minRAMGB: 8,
            role: .generator, tier: "Small",
            strengths: "Smallest and fastest; lowest quality, good for quick smoke tests."),
    ]

    public static let embedders: [CatalogModel] = [
        CatalogModel(
            key: "qwen3-embed-0.6b", repoID: "mlx-community/Qwen3-Embedding-0.6B-4bit-DWQ",
            revision: "6c3ae70858513f1a78e9cdca3cae330d9075cd2a",
            displayName: "Qwen3-Embedding-0.6B (4-bit DWQ)", approxSizeGB: 0.35, minRAMGB: 8,
            role: .embedder, tier: "Embedder",
            strengths: "Top-MTEB-tier embeddings while staying tiny; the default."),
        CatalogModel(
            key: "bge-small", repoID: "BAAI/bge-small-en-v1.5",
            revision: "5c38ec7c405ec4b44b94cc5a9bb96e735b38267a",
            displayName: "BGE-small-en v1.5", approxSizeGB: 0.13, minRAMGB: 8, role: .embedder,
            tier: "Embedder", strengths: "Fastest, smallest embedder (384-dim, 512 ctx)."),
        CatalogModel(
            key: "nomic-1.5", repoID: "nomic-ai/nomic-embed-text-v1.5",
            revision: "e9b6763023c676ca8431644204f50c2b100d9aab",
            displayName: "Nomic Embed Text v1.5", approxSizeGB: 0.55, minRAMGB: 8, role: .embedder,
            tier: "Embedder", strengths: "Long-context embeddings (8K) for longer hypotheses."),
    ]

    public static var all: [CatalogModel] { generators + embedders }

    public static let defaultGeneratorKey = "qwen3-4b"
    public static let defaultEmbedderKey = "qwen3-embed-0.6b"

    public static var defaultGenerator: CatalogModel { model(key: defaultGeneratorKey)! }
    public static var defaultEmbedder: CatalogModel { model(key: defaultEmbedderKey)! }

    public static func model(key: String) -> CatalogModel? { all.first { $0.key == key } }
    public static func model(repoID: String) -> CatalogModel? { all.first { $0.repoID == repoID } }

    public static func org(of repoID: String) -> String {
        repoID.split(separator: "/").first.map(String.init) ?? ""
    }

    public static func isTrusted(repoID: String) -> Bool { trustedOrgs.contains(org(of: repoID)) }

    /// Resolve a catalog key or raw HF repo id into a load plan + trust level.
    public static func resolve(_ keyOrID: String) -> ResolvedModel {
        if let m = model(key: keyOrID) ?? model(repoID: keyOrID) {
            return ResolvedModel(repoID: m.repoID, revision: m.revision, trust: .catalog)
        }
        let trust: ResolvedModel.Trust = isTrusted(repoID: keyOrID) ? .trustedOrg : .unverified
        return ResolvedModel(repoID: keyOrID, revision: nil, trust: trust)
    }
}
