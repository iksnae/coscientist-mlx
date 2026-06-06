/// Pure rules for a study's title relative to its goal (M22). The title auto-tracks the goal's
/// first line until the user names the study; an empty title is *not* treated as custom, so it
/// resumes tracking (fixing the "Untitled study" stuck state). Lists fall back to the goal when
/// the title is blank.
public enum StudyTitle {
    /// Whether an edited title should be considered user-set (custom): non-empty and different
    /// from what the goal would derive. Empty/whitespace → not custom (resume goal-tracking).
    public static func isCustom(editedTitle: String, goal: String) -> Bool {
        let trimmed = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return trimmed != StudyConfig.defaultTitle(forGoal: goal)
    }

    /// The name to show for a study: the title if set, else the goal's first line, else a generic
    /// placeholder.
    public static func display(title: String, goal: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let goalTrimmed = goal.trimmingCharacters(in: .whitespacesAndNewlines)
        return goalTrimmed.isEmpty ? "Untitled study" : StudyConfig.defaultTitle(forGoal: goal)
    }
}
