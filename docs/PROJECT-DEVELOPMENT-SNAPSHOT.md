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

- **M10 — Foundation Models backend** (PR #36). Gated
  `AICoScientistFoundationModels` adapter + `InferenceBackend` resolver;
  CLI `--backend` + app picker. See `docs/MILESTONE-10-CLOSEOUT.md`.
  134 tests / 30 suites; macOS app builds.
- **M9 — Transparent activity** (PR #35). See `docs/MILESTONE-9-CLOSEOUT.md`.
- **M8 — Hypothesis selection + inspector** (PR #34).
- **M7 — Hosted per-agent model backing** (PR #31).
- **M6 — Agent tool-use loop** (PR #30).
- Earlier: M0–M5 numbered milestones; post-M5 feature work (PRs #6–#29).

## Next in flight

- **M11 — Inference optimization** — `docs/MILESTONE-11-PLANNING-DRAFT.md`.
  Prompt/KV cache reuse + quant tiers. Next to grind (last of the
  2026-06-04 batch).

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
