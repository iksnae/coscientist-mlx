import SwiftUI

// MARK: - Design-token typography system

/// Single source of truth for all typography in the CoScientist UI.
///
/// Views consume **semantic presets** (``caption2``, ``body``, ``headline``, …),
/// never raw font sizes. This keeps the type scale consistent and
/// Dynamic-Type-friendly across every screen.
///
/// Every preset uses **SF Pro** (the system default) and participates in
/// Dynamic Type, so text scales automatically with the user's preferred
/// reading size.
enum TypographyTokens {
    /// Caption 2 — smallest label size.
    static let caption2 = Font.caption2

    /// Caption — small supporting text.
    static let caption = Font.caption

    /// Callout — slightly-emphasised secondary text.
    static let callout = Font.callout

    /// Subheadline — secondary heading text.
    static let subheadline = Font.subheadline

    /// Body — default reading size.
    static let body = Font.body

    /// Headline — emphasised body-level text.
    static let headline = Font.headline

    /// Title 3 — smaller title.
    static let title3 = Font.title3

    /// Title 2 — medium title.
    static let title2 = Font.title2
}
