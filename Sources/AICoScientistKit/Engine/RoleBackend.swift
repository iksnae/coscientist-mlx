/// A per-role backend choice: keep the role on the local (default) decoder, or route it to a
/// specific hosted model. The single loaded local model backs every `.local` role; the value
/// that varies per role is which hosted model to use, so only `.remote` carries an id.
public enum RoleBackend: Sendable, Equatable {
    case local
    case remote(String)
}

extension RoleDecoderRouter {
    /// Build a router from per-role backend assignments. `.remote(id)` roles resolve to
    /// `makeRemote(id)`; `.local` and unassigned roles resolve to `base`. With no assignments
    /// every role uses `base`, so "all local" is the default (local-first). `makeRemote` is
    /// called only for the roles actually assigned a remote model.
    public static func backed(
        default base: any SchemaConstrainedDecoding,
        backends: [AgentRole: RoleBackend],
        makeRemote: (String) -> any SchemaConstrainedDecoding
    ) -> RoleDecoderRouter {
        var overrides: [AgentRole: any SchemaConstrainedDecoding] = [:]
        for (role, backend) in backends {
            if case let .remote(id) = backend {
                overrides[role] = makeRemote(id)
            }
        }
        return RoleDecoderRouter(default: base, overrides: overrides)
    }
}
