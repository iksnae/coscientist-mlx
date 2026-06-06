# Milestone 23 Implementation Plan

Date: 2026-06-05
Status: Plan — ready for review

## Summary

Establish a SwiftUI design-token foundation (color, typography, spacing, elevation, status) in `Apps/Shared/DesignTokens/`, a testable `DesignSemantics` helper in `Sources/AICoScientistKit/`, a repo-root `DESIGN.md`, and incremental token adoption in 3 core views.

---

## Step 1 — DesignSemantics: testable pure-logic status mapping

**Rationale:** The status→label/severity mapping must be unit-testable per DoD. Embedding it in AICoScientistKit (the already-tested library) lets `swift test` cover it without SwiftUI/Xcode app dependencies. The apps consume it via the existing `import AICoScientistKit`.

**Files to create:**
- `Sources/AICoScientistKit/Design/DesignSemantics.swift` — `DesignStatus` enum (draft/running/done/error) with computed `label` and `severity` properties; zero SwiftUI imports.
- `Tests/AICoScientistKitTests/DesignSemanticsTests.swift` — Swift Testing suite covering all four statuses' label/severity.

**Verification:** `swift test --filter DesignSemanticsTests`

---

## Step 2 — SwiftUI DesignTokens in Apps/Shared

**Rationale:** The brand palette, type scale, spacing scale, elevation/radius, and status colors are all SwiftUI-dependent (Color, Font); they belong in the shared app layer. A single `Theme` namespace wraps them for ergonomic use (`Theme.color.surface`, `Theme.space.md`).

**Files to create:**
- `Apps/Shared/DesignTokens/ColorTokens.swift` — brand hex palette (#070b14, #0e1726, #22d3ee, #2dd4bf, #38bdf8, #fbbf24, #e6edf3) as `Color` extensions; semantic-role aliases (background, surface, accent, success, warning, textPrimary/textSecondary).
- `Apps/Shared/DesignTokens/TypographyTokens.swift` — SF Pro type scale (caption2, caption, callout, body, headline, title3, title2) with Dynamic-Type-friendly `.font()` presets.
- `Apps/Shared/DesignTokens/SpacingTokens.swift` — 8pt spacing scale (xs=4, sm=8, md=16, lg=24, xl=32, xxl=48), corner radius tiers, shadow/elevation presets.
- `Apps/Shared/DesignTokens/Theme.swift` — `Theme` enum namespace re-exporting `Theme.color`, `Theme.text`, `Theme.space`, `Theme.radius`, `Theme.elevation`, `Theme.status`.

**Verification:** `ls Apps/Shared/DesignTokens/Theme.swift Apps/Shared/DesignTokens/ColorTokens.swift Apps/Shared/DesignTokens/TypographyTokens.swift Apps/Shared/DesignTokens/SpacingTokens.swift >/dev/null 2>&1`

---

## Step 3 — DESIGN.md at repo root

**Rationale:** A single source of truth for the design system that the team and design skills reference. Documents the palette with hex values + contrast pairs, type scale, spacing, elevation, component do/don'ts, and the image-gen prompt suffix from the established brand.

**Files to create:**
- `DESIGN.md` — sections: 1) Palette (hex + semantic roles + WCAG AA contrast pairs), 2) Typography (SF Pro scale + Dynamic Type), 3) Spacing (8pt scale), 4) Elevation & Radius, 5) Status colors, 6) Component styling guidelines (do/don'ts), 7) Image-gen prompt suffix.

**Verification:** `grep -q '^## Palette' DESIGN.md && grep -q '^## Typography' DESIGN.md && grep -q '^## Spacing' DESIGN.md && grep -q '^## Elevation' DESIGN.md && grep -q '^## Status' DESIGN.md && grep -q '^## Component' DESIGN.md && grep -q 'image.gen' DESIGN.md`

---

## Step 4 — Convert ≥3 core views to tokens

**Rationale:** Incremental adoption — prove the token system works on real views before mass-refactoring in M24–M26. Three views spanning the key UI surfaces: live progress (RunProgressView), list row (StudyRow), and results conclusion (StudyDetailView conclusion block).

**Files to modify:**
- `Apps/Shared/RunProgressView.swift` — replace raw `.font(.caption2…)`, `.foregroundStyle(.secondary)`, hardcoded `spacing:`, `Color.secondary.opacity(…)`, `.tint` with `Theme.text.*`, `Theme.color.*`, `Theme.space.*`.
- `Apps/Shared/Study.swift` (StudyRow) — replace status-dot `color` switch (`.blue`/`.green`/`.red`/`.secondary`) with `Theme.status.color(for: study.status)`.
- `Apps/Shared/StudyDetailView.swift` (Conclusion block) — replace `.green.opacity(0.06)`, `.orange.opacity(0.08)`, hardcoded fonts/spacing with `Theme.color.success.background`, `Theme.color.warning.background`, `Theme.text.*`, `Theme.space.*`.

**Verification:** `swift build`

---

## Step 5 — Full-build and test gate

**Rationale:** Ensure the package builds cleanly, all existing + new tests pass, and DESIGN.md is structurally complete. This is the final DoD gate.

**Verification:** `swift build && swift test && grep -q '^## Palette' DESIGN.md && grep -q 'image.gen' DESIGN.md`
