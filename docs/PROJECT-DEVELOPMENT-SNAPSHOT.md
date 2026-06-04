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

- **M7 — Hosted per-agent model backing** (PR #31). Model discovery,
  `RoleBackend`/`RoleDecoderRouter.backed`, CLI `--agent-model`, app
  presets + per-agent pickers. See `docs/MILESTONE-7-CLOSEOUT.md`.
  123 tests / 26 suites; macOS app builds.
- **M6 — Agent tool-use loop** (PR #30). See `docs/MILESTONE-6-CLOSEOUT.md`.
- Earlier: M0–M5 numbered milestones; post-M5 feature work (PRs #6–#29).

## Next in flight

- **M8 — Hypothesis selection + inspector** — `docs/MILESTONE-8-PLANNING-DRAFT.md`.
  Results-presentation UX (select a hypothesis in the list/graph, inspect
  its full detail) pulled ahead on operator signal. Next to grind.
- Drafts queued: **M9** transparent activity feed, **M10** Foundation
  Models backend (deferred from M8), **M11** inference optimization.

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
