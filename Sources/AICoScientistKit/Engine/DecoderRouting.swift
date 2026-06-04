/// The pipeline roles a decode can belong to. Used to route each agent to a backend —
/// e.g. local generation, remote judge for the tournament.
public enum AgentRole: String, Sendable, CaseIterable, Codable {
    case generation
    case reflection
    case ranking
    case evolution
    case metaReview
    case tournament
    case proximity
}

/// Supplies the structured decoder to use for a given agent role. The engine depends on
/// this (not a single decoder), so backends can be mixed per stage without engine changes.
public protocol DecoderRouting: Sendable {
    func decoder(for role: AgentRole) -> any SchemaConstrainedDecoding
}

/// One decoder for every role — the default, backward-compatible behavior.
public struct StaticDecoderRouter: DecoderRouting {
    private let decoder: any SchemaConstrainedDecoding

    public init(_ decoder: any SchemaConstrainedDecoding) {
        self.decoder = decoder
    }

    public func decoder(for role: AgentRole) -> any SchemaConstrainedDecoding { decoder }
}

/// Per-role routing: a default decoder plus optional overrides. The classic split is local
/// generation/evolution + a stronger remote judge for reflection/tournament.
public struct RoleDecoderRouter: DecoderRouting {
    private let fallback: any SchemaConstrainedDecoding
    private let overrides: [AgentRole: any SchemaConstrainedDecoding]

    public init(
        default fallback: any SchemaConstrainedDecoding,
        overrides: [AgentRole: any SchemaConstrainedDecoding] = [:]
    ) {
        self.fallback = fallback
        self.overrides = overrides
    }

    public func decoder(for role: AgentRole) -> any SchemaConstrainedDecoding {
        overrides[role] ?? fallback
    }
}
