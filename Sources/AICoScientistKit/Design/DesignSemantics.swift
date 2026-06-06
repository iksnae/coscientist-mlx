/// Pure-logic design semantics: status labels and severity levels for hypotheses and runs.
/// Zero SwiftUI/AppKit dependencies — usable from both the kit and the apps.
public enum DesignStatus: Equatable, Sendable {
    case draft
    case running
    case done
    case error

    /// Human-readable label for the status.
    public var label: String {
        switch self {
        case .draft: return "Draft"
        case .running: return "Running"
        case .done: return "Done"
        case .error: return "Error"
        }
    }

    /// Numeric severity — higher means more urgent / terminal.
    public var severity: Int {
        switch self {
        case .draft: return 0
        case .running: return 1
        case .done: return 2
        case .error: return 3
        }
    }
}
