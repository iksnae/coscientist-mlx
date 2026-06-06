import AICoScientistKit
import SwiftUI

// MARK: - Central Design-token namespace

/// Single import point for every design token in the CoScientist UI.
///
/// ```swift
/// Text("Running").foregroundStyle(Theme.status.color(for: .running))
/// HStack(spacing: Theme.space.Spacing.sm) { … }
/// ```
///
/// Views should **never** reach into ``ColorTokens``, ``TypographyTokens``, or
/// ``SpacingTokens`` directly — always go through `Theme`.
enum Theme {
    // MARK: - Color

    /// Semantic color roles — re-exports ``ColorTokens``.
    typealias color = ColorTokens

    // MARK: - Typography

    /// Typography presets — re-exports ``TypographyTokens``.
    typealias text = TypographyTokens

    // MARK: - Spacing & radius

    /// Layout constants: the 8‑pt spacing scale and corner-radius presets.
    enum space {
        /// 8‑pt spacing scale (xs … xxl).
        typealias Spacing = SpacingTokens.Spacing

        /// Corner-radius presets (sm / md / lg).
        typealias Radius = SpacingTokens.CornerRadius
    }

    // MARK: - Elevation

    /// Elevation presets.
    ///
    /// The actual modifiers are defined as `View` extensions:
    /// ```swift
    /// card.elevationLow()
    /// modal.elevationHigh()
    /// ```
    ///
    /// ``elevation`` exists as a namespace so every design concept has a
    /// discoverable home under `Theme`.
    enum elevation {}

    // MARK: - Status

    /// Maps ``StudyStatus`` to semantic colors, labels, and severities.
    ///
    /// Delegates to the pure-logic ``DesignStatus`` enum (in AICoScientistKit)
    /// for label and severity lookups so the Kit's business rules stay single-source.
    enum status {
        /// The semantic color for a given study status.
        ///
        /// | Status    | Color                                      |
        /// |-----------|--------------------------------------------|
        /// | `.draft`  | ``ColorTokens/textSecondary``              |
        /// | `.running`| ``ColorTokens/accent`` (cyan)              |
        /// | `.done`   | ``ColorTokens/success`` (teal)             |
        /// | `.error`  | `Color.red`                                |
        public static func color(for studyStatus: StudyStatus) -> Color {
            switch studyStatus {
            case .draft:
                return ColorTokens.textSecondary
            case .running:
                return ColorTokens.accent
            case .done:
                return ColorTokens.success
            case .error:
                return .red
            }
        }

        /// The human-readable label for a given study status.
        public static func label(for studyStatus: StudyStatus) -> String {
            designStatus(for: studyStatus).label
        }

        /// Numeric severity — higher means more urgent.
        public static func severity(for studyStatus: StudyStatus) -> Int {
            designStatus(for: studyStatus).severity
        }

        // MARK: Private helpers

        /// Bridges the app-level ``StudyStatus`` to the Kit's pure-logic ``DesignStatus``.
        private static func designStatus(for studyStatus: StudyStatus) -> DesignStatus {
            switch studyStatus {
            case .draft:   return .draft
            case .running: return .running
            case .done:    return .done
            case .error:   return .error
            }
        }
    }
}
