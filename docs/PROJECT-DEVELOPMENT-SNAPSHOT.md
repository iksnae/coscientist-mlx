# Project Development Snapshot

A one-screen "where are we right now" pointer. `milestone-grinder`
Phase 2 bumps this every cycle. Keep it short — detail lives in the
linked docs.

Snapshot date: 2026-06-04

## State

Hybrid routing + feature parity + public docs + agent grounding. The
seven-agent pipeline runs on-device end-to-end
(`swift run aicoscientist "<goal>" --run`), with optional
`--remote-judge` hybrid routing and opt-in `--tools` grounding
(arXiv/PubMed/web) for generation + reflection. Verified on macOS and
on iPhone. M0–M6 landed; the CLI, routing, model catalog, demo apps,
and DocC site shipped as feature PRs.

## Last shipped

- **M6 — Agent tool-use loop + grounded Generation/Reflection** (PR #30).
  `GroundedDecoder` ReAct loop + research tools wired via routing + CLI
  `--tools`. See `docs/MILESTONE-6-CLOSEOUT.md`. 116 tests / 24 suites.
- Earlier: M0–M5 numbered milestones; post-M5 feature work (routing,
  remote adapter, catalog, apps, DocC, charts, settings, studies,
  node-graph, agent tools — PRs #6–#29).

## Next in flight

- **M7 — Hosted per-agent model backing** — `docs/MILESTONE-7-PLAN.md`
  (Ready). Model discovery + per-role backend assignment; de-risks the
  M6 tool-use loop. Drafts queued: M8 (Foundation Models), M9 (graph
  inspector), M10 (optimization).

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
