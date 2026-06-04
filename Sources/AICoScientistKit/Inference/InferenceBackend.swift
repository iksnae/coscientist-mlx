/// Which on-device inference backend generates text. MLX (any open model) is the default;
/// Apple Foundation Models is an optional, availability-gated alternative. The concrete FM
/// adapter lives in `AICoScientistFoundationModels`; this enum is the provider-agnostic
/// selection seam the CLI and app resolve against.
public enum InferenceBackend: String, Sendable, CaseIterable, Codable {
    case mlx
    case foundation

    /// The effective backend: Foundation Models only when actually available, otherwise MLX.
    /// Local-first and device-agnostic — a `.foundation` request on an unsupported device
    /// degrades to `.mlx` rather than failing.
    public static func resolve(
        requested: InferenceBackend, foundationAvailable: Bool
    ) -> InferenceBackend {
        switch requested {
        case .mlx: return .mlx
        case .foundation: return foundationAvailable ? .foundation : .mlx
        }
    }
}
