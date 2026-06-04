# Project Development Snapshot

A one-screen "where are we right now" pointer. `milestone-grinder`
Phase 2 bumps this every cycle. Keep it short — detail lives in the
linked docs.

Snapshot date: 2026-06-04

## State

Hybrid routing + feature parity + public docs. The seven-agent pipeline
runs on-device end-to-end (`swift run aicoscientist "<goal>" --run`),
with optional `--remote-judge` hybrid routing. Verified on macOS and
on iPhone. M0–M5 landed as numbered milestones; the CLI, routing,
model catalog, demo apps, and DocC site shipped as feature PRs.

## Last shipped

- **M5 — Embedding proximity** (last numbered milestone). See
  `docs/ARCHITECTURE.md` §6 and the M5 line in `docs/ROADMAP.md`.
- Post-M5 feature work: per-stage `DecoderRouting`, remote adapter,
  model catalog, macOS/iOS apps, DocC site (PRs #6–#19).

## Next in flight

Nothing promoted yet — the milestone loop is being adopted now. The
next numbered milestone is **M6**. Run `milestone-planner` to turn a
roadmap theme (Optimization or Parity-test harness) plus your intention
into a `MILESTONE-6-PLANNING-DRAFT.md`, then `milestone-grinder` to
promote and deliver it.

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
