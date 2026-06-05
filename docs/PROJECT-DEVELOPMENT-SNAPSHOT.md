# Project Development Snapshot

A one-screen "where are we right now" pointer. `milestone-grinder`
Phase 2 bumps this every cycle. Keep it short — detail lives in the
linked docs.

Snapshot date: 2026-06-04

## State

Hybrid routing + feature parity + public docs + agent grounding +
per-agent backing. The seven-agent pipeline runs on-device end-to-end
(`swift run aicoscientist "<goal>" --run`), with opt-in `--tools`
grounding (arXiv/PubMed/web) and per-role hosted backing
(`--agent-model role=id`, or the app's Providers tab). Verified on macOS
and on iPhone. M0–M7 landed.

## Last shipped

- **M12 — Shared app core + iOS (iPhone) parity** (PRs #42, #43).
  Cross-platform model + views extracted to `Apps/Shared`; the full demo
  builds + runs on iOS (Studies, run, results + inspector, activity,
  Settings, charts, graph, export). See `docs/MILESTONE-12-CLOSEOUT.md`.
  138 tests / 32 suites; macOS + iOS apps build.
- **M11 — Batched reflection** (PR #39). See `docs/MILESTONE-11-CLOSEOUT.md`.
- **M10 — Foundation Models backend** (PR #36).
- **M6–M9** — tool-use loop, hosted backing, inspector, activity (PRs #30–#35).
- Earlier: M0–M5 numbered milestones; post-M5 feature work (PRs #6–#29).

## Next in flight

A user-layer control-flow + UX overhaul is drafted (mac first, then iOS),
driven by the vendored Swift UI/UX skills:

- **M13 — Model selection control-flow (macOS)** —
  `docs/MILESTONE-13-PLANNING-DRAFT.md`. Per-study Generator + Reviewer
  (each on-device | hosted); install-aware pickers; Settings = providers +
  downloads. Next to grind.
- **M14 — Run config + results outcome (macOS)** — expose hidden engine
  params + a results header that states the conclusion. *(draft)*
- **M15 — iOS** — port the redesign + iPad-adaptive layout + on-device
  hardening (absorbs the earlier iPad-polish scope). *(draft)*
- Candidate themes (see `docs/ROADMAP.md`): parity-test harness, native
  Foundation Models tool calling.

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
