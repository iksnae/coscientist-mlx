import SwiftUI

// MARK: - Design-token spacing system

/// Single source of truth for all spacing, corner radii, and elevation presets
/// in the CoScientist UI.
///
/// Views consume **semantic constants** (``SpacingTokens.Spacing.md``,
/// ``SpacingTokens.CornerRadius.sm``) and **view-modifier presets**
/// (``SwiftUICore/View/elevationLow()``, …), never raw magic numbers.
/// This keeps layout rhythm consistent across every screen.

// MARK: - Spacing scale (8 pt grid)

/// 8‑point spacing scale — every value is a multiple of 8.
///
/// Use these for padding, gap, stack spacing, and any other layout offset.
/// ```swift
/// HStack(spacing: SpacingTokens.Spacing.sm) { … }
/// ```
enum SpacingTokens {
    // MARK: Spacing constants

    /// 8‑pt spacing scale constants.
    enum Spacing {
        /// Extra-small — 4 pt. For tight inline gaps.
        public static let xs: CGFloat = 4

        /// Small — 8 pt. Default inter‑item gap.
        public static let sm: CGFloat = 8

        /// Medium — 16 pt. Standard section padding.
        public static let md: CGFloat = 16

        /// Large — 24 pt. Block-level separation.
        public static let lg: CGFloat = 24

        /// Extra-large — 32 pt. Major section breaks.
        public static let xl: CGFloat = 32

        /// Double extra-large — 48 pt. Page-level margins.
        public static let xxl: CGFloat = 48
    }

    // MARK: Corner-radius tiers

    /// Corner-radius presets for rounded rectangles, cards, and buttons.
    enum CornerRadius {
        /// Small — 4 pt. Subtle rounding for inline elements (chips, badges).
        public static let sm: CGFloat = 4

        /// Medium — 8 pt. Standard rounding for cards and rows.
        public static let md: CGFloat = 8

        /// Large — 12 pt. Generous rounding for modals and prominent surfaces.
        public static let lg: CGFloat = 12
    }
}

// MARK: - Elevation / shadow presets (View modifiers)

extension View {
    /// Low elevation — subtle lift off the deep-navy background.
    ///
    /// A tight, low-opacity glow that gives cards and inactive surfaces a
    /// gentle sense of depth without competing for attention.
    public func elevationLow() -> some View {
        self.shadow(
            color: .black.opacity(0.35),
            radius: 3,
            x: 0,
            y: 1
        )
    }

    /// Medium elevation — moderate lift for interactive surfaces.
    ///
    /// Slightly larger radius and more opacity; appropriate for hover states,
    /// floating panels, and popovers.
    public func elevationMedium() -> some View {
        self.shadow(
            color: .black.opacity(0.45),
            radius: 6,
            x: 0,
            y: 2
        )
    }

    /// High elevation — pronounced lift for modal overlays and sheets.
    ///
    /// Maximum depth cue; reserved for the topmost layer of the UI so the
    /// user's attention is drawn to the modal content.
    public func elevationHigh() -> some View {
        self.shadow(
            color: .black.opacity(0.55),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}
