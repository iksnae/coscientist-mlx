import SwiftUI

// MARK: - Design-token color system

/// Single source of truth for all colors in the CoScientist UI.
///
/// Views consume **semantic roles** (``background``, ``accent``, ``textPrimary``, …),
/// never raw hex values. This keeps the palette swappable — change a role's mapping
/// and every screen updates consistently.
///
/// The palette is a single dark-theme set; the app targets a deep-navy baseline
/// that reads well on any Apple Silicon Mac or iPad display.
enum ColorTokens {
    // MARK: Raw palette

    /// Deep navy — primary background (#070b14)
    static let deepNavy      = Color(red: 7  / 255, green: 11  / 255, blue: 20  / 255)
    /// Elevated surface — cards, sheets, grouped rows (#0e1726)
    static let elevatedSurface = Color(red: 14 / 255, green: 23  / 255, blue: 38  / 255)
    /// Cyan accent — primary interactive elements (#22d3ee)
    static let cyanAccent    = Color(red: 34 / 255, green: 211 / 255, blue: 238 / 255)
    /// Teal — success / positive (#2dd4bf)
    static let teal          = Color(red: 45 / 255, green: 212 / 255, blue: 191 / 255)
    /// Sky — informational (#38bdf8)
    static let sky           = Color(red: 56 / 255, green: 189 / 255, blue: 248 / 255)
    /// Amber — warning / alert (#fbbf24)
    static let amber         = Color(red: 251 / 255, green: 191 / 255, blue: 36  / 255)
    /// Off-white — primary text (#e6edf3)
    static let offWhite      = Color(red: 230 / 255, green: 237 / 255, blue: 243 / 255)

    // MARK: Semantic roles

    /// App-wide background (full-screen, window).
    static let background    = deepNavy

    /// Elevated card / sheet / group-row surface.
    static let surface       = elevatedSurface

    /// Primary accent — buttons, links, active states, progress.
    static let accent        = cyanAccent

    /// Success / confirmed / positive state.
    static let success       = teal

    /// Warning / attention / pending state.
    static let warning       = amber

    /// Success background — subtle teal tint for positive-outcome banners.
    static let successBackground = teal.opacity(0.06)

    /// Warning background — subtle amber tint for warning/issue banners.
    static let warningBackground = amber.opacity(0.08)

    /// Primary body text.
    static let textPrimary   = offWhite

    /// Subdued secondary text (captions, metadata, placeholders).
    static let textSecondary = offWhite.opacity(0.65)
}
