# Milestone 23 Planning Draft

Date: 2026-06-05

Working name:

```txt
Design tokens + DESIGN.md (foundation)
```

## Status

Draft. Not yet promoted to MILESTONE-23-PLAN.md.

## Goal

Establish a SwiftUI **design-token foundation** (color, typography, spacing,
elevation, status) derived from the brand, plus a repo-root **DESIGN.md** —
so views stop hand-rolling styles and the overhaul (M24–M26) builds on one
system. Foundation + **incremental adoption**: define tokens, author
DESIGN.md, convert a few core views as proof; later milestones adopt tokens
as they touch each view.

## Context

The design-first artifacts are done: `docs/DESIGN-IA.md`,
`docs/DESIGN-WIREFRAMES.md`, `docs/assets/mockups/`. Today styling is ad-hoc
per view; the brand palette only lives in docs/images. Operator approved
"tokens first" + authoring DESIGN.md now (also unblocks the impeccable/
designer skills, which expect DESIGN.md). First of a 4-milestone build batch,
ahead of M19.

## Usage Scenarios

### Scenario 1: Consistent styling
- A developer styles a view using named tokens (`Theme.color.accent`,
  `Theme.space.md`, `Theme.text.title`) rather than raw hex/points; the app
  reads cohesively and dark-mode/Dynamic-Type behave.

### Scenario 2: Brand source of truth
- DESIGN.md at the repo root documents the palette, type scale, spacing,
  elevation, component stylings, and the image-gen prompt suffix — one place
  the team + design skills reference.

## Primary Scope

### Track A — SwiftUI tokens (Apps/Shared)
A `DesignTokens` (a.k.a. `Theme`) namespace: brand **colors** (deep navy
#070b14/#0e1726 surfaces, cyan #22d3ee, teal #2dd4bf, sky #38bdf8, amber
#fbbf24, off-white #e6edf3 text) as semantic roles (background, surface,
accent, success, warning, textPrimary/Secondary); **typography** scale
(SF Pro, Dynamic-Type-friendly), **spacing** (8pt scale), **radius/
elevation**, **status** colors (draft/running/done/error). UI-free derived
mappings (e.g. `StudyStatus → semantic color/label`) go in a small testable
helper.

### Track B — DESIGN.md (repo root)
Author DESIGN.md: palette (hex + semantic roles + contrast pairs),
typography, spacing, elevation, component do/don'ts, and a §9 image-gen
prompt suffix matching the established brand (for designer/impeccable).

### Track C — Convert core views as proof
Adopt tokens in ≥3 core views (e.g. `RunProgressView`, `StudyRow`, the
Conclusion block) to validate the system; run `design-audit` as a baseline.

## Definition Of Done

- `DesignTokens`/`Theme` exists in `Apps/Shared` with color/type/spacing/
  elevation/status tokens; used in ≥3 views.
- Any pure token-derived logic (e.g. status→semantic mapping) is unit-tested.
- `DESIGN.md` exists at the repo root (palette + type + spacing + elevation +
  components + image-gen suffix); contrast pairs documented (WCAG AA targets).
- `design-audit` baseline recorded in the closeout.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M23 tracking + closeout docs land with the final commit.

## Non-Goals

- Re-laying-out screens (that is M24–M26) — this is the token layer + proof.
- Converting every view to tokens now (incremental adoption per the decision).
- New engine behavior; LAN offload (M19).

## Open Questions

- **[?]** Token delivery: Asset Catalog color sets (free dark/light + Xcode
  preview) vs `Color` extensions in code. Lean: asset-catalog colors for the
  palette + a Swift `Theme` for spacing/type/semantic roles.

## Risk

- **Token churn vs incremental adoption.** Mitigation: define + prove on a
  few views; don't mass-refactor (adopt as views are touched in M24–M26).

## Scope Class

Small–Medium. New token layer + DESIGN.md + a few view conversions.
