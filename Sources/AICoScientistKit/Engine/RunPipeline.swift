/// The canonical ordered agent pipeline, for progress visualization. The engine emits a phase
/// string per step (`WorkflowProgress.phase`); this maps those to ordered, human-labeled stages
/// so the UI can show a breadcrumb of where a run is. Pure + testable (UI-free).
public enum RunPipeline {
    /// The seven stages in pipeline order (the refinement loop revisits some of them; this is the
    /// canonical sequence used for the progress breadcrumb).
    public static let stages: [ActivityEvent.Kind] = [
        .generation, .reflection, .ranking, .tournament, .metaReview, .evolution, .proximity,
    ]

    /// The 0-based stage index for a `WorkflowProgress.phase` string, or `nil` for a non-pipeline
    /// phase (`tool`, `other`, unknown, empty).
    public static func stageIndex(forPhase phase: String) -> Int? {
        stages.firstIndex(of: ActivityEvent.Kind(phase: phase))
    }

    /// Human-readable label for a stage.
    public static func displayName(_ kind: ActivityEvent.Kind) -> String {
        switch kind {
        case .generation: "Generation"
        case .reflection: "Reflection"
        case .ranking: "Ranking"
        case .tournament: "Tournament"
        case .metaReview: "Meta-Review"
        case .evolution: "Evolution"
        case .proximity: "Proximity"
        case .tool: "Tools"
        case .other: "—"
        }
    }
}
