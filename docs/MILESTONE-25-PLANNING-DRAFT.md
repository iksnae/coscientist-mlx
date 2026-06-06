# Milestone 25 Planning Draft

Date: 2026-06-05

Working name:

```txt
Models top-level destination + navigation shells
```

## Status

Draft. Not yet promoted to MILESTONE-25-PLAN.md.

## Goal

Promote **Models** to a **top-level destination** and implement the
per-platform navigation shells from the IA: macOS/iPad `NavigationSplitView`
with sidebar destinations (**Studies / Models**) + list + detail + inspector
pane; iPhone single Studies stack with Models/Settings as sheets. Settings
slims to app-level prefs.

## Context

Builds on M23 tokens + M24's Results-first detail. Today Models + Providers
live as tabs inside Settings; the IA makes Models a primary destination
(unified on-device catalog + hosted providers + embedder). The catalog
download/delete/progress UI already exists in `SettingsView` (M20/feature
PRs) and is reused. Third of the build batch.

## Usage Scenarios

### Scenario 1: Models as a place
- From the sidebar (iPad/macOS) or a toolbar button (iPhone), the user opens
  **Models** to download/delete on-device models, set the default embedder,
  and configure the hosted provider — one home for "what models do I have."

### Scenario 2: Coherent shells
- macOS/iPad: a sidebar switches Studies/Models; the study detail + inspector
  use the split view. iPhone: a Studies stack; Models + Settings open as sheets.

## Primary Scope

### Track A — Navigation shell (Apps/Shared)
A root that exposes **Studies** and **Models** as destinations:
`NavigationSplitView` with a sidebar destination switch on regular width;
on iPhone (compact) a Studies stack with toolbar buttons opening **Models**
and **Settings** sheets. Preserve the M15 size-class-adaptive inspector.

### Track B — Models destination view
A `ModelsView` unifying: **On-device catalog** (rows with size, downloaded ✓ /
Download (disk guard + progress) / Delete, compatibility) — reusing the
existing `ModelDownloader` + catalog UI; **Default embedder**; **Hosted
provider** (base URL, API key + "Get a key" link, model + Refresh). Tokens
from M23.

### Track C — Slim Settings
Reduce `SettingsView` to app-level prefs: iCloud sync status, Hugging Face
token, About. Remove the Models/Providers tabs (moved to the destination).

## Definition Of Done

- **Models** is reachable as a top-level destination on macOS, iPad
  (sidebar), and iPhone (toolbar sheet); it contains catalog + embedder +
  provider with working download/delete.
- Settings is slimmed to iCloud status + HF token + About.
- Navigation shells match the IA per platform; inspector pane/sheet preserved.
- Uses M23 tokens; copy via `writing-for-interfaces`.
- `swift build` clean; `swift test` green; macOS + iOS apps build.
- `import MLX*` only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M25 tracking + closeout land with the final commit.

## Non-Goals

- New model/provider capabilities (reuse existing download/provider logic).
- Inspector/viz polish + a11y (M26).
- LAN model offload (M19).

## Open Questions

- **[?]** macOS destination switch: a sidebar section header list (Studies/
  Models) vs a top-level `TabView`-in-sidebar. Lean: sidebar list of
  destinations driving the split-view content.

## Risk

- **Restructuring the app root** (NavigationSplitView destinations) risks
  regressions to study selection / inspector. Mitigation: keep SwiftData
  `@Query` + selection model; build both apps; operator device check.

## Scope Class

Medium.
