/// A per-study model choice: an on-device catalog model (key or repo id) or a hosted model id.
/// The single, explicit way a Study says which model backs a role — replacing the scattered
/// generator-key / backend / per-agent-backing / hosted-toggle controls.
public enum ModelChoice: Sendable, Equatable, Codable {
    case onDevice(String)
    case hosted(String)
}

/// Builds the engine's `DecoderRouting` from a Study's Generator + Reviewer choices. The
/// generator backs generation, evolution, ranking, and meta-review; the reviewer backs the
/// judging roles (reflection + tournament). With both on-device, every role stays local.
public enum StudyRouting {
    /// Roles the Reviewer choice backs; everything else follows the Generator.
    public static let reviewerRoles: Set<AgentRole> = [.reflection, .tournament]

    public static func router(
        generator: ModelChoice,
        reviewer: ModelChoice,
        makeOnDevice: (String) -> any SchemaConstrainedDecoding,
        makeHosted: (String) -> any SchemaConstrainedDecoding
    ) -> any DecoderRouting {
        func decoder(for choice: ModelChoice) -> any SchemaConstrainedDecoding {
            switch choice {
            case .onDevice(let key): return makeOnDevice(key)
            case .hosted(let id): return makeHosted(id)
            }
        }
        let generatorDecoder = decoder(for: generator)
        let reviewerDecoder = decoder(for: reviewer)
        let overrides = Dictionary(
            uniqueKeysWithValues: reviewerRoles.map { ($0, reviewerDecoder) })
        return RoleDecoderRouter(default: generatorDecoder, overrides: overrides)
    }
}
