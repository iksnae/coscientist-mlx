# Project Development Snapshot

A one-screen "where are we right now" pointer. `milestone-grinder`
Phase 2 bumps this every cycle. Keep it short — detail lives in the
linked docs.

Snapshot date: 2026-06-05

## State

Hybrid routing + feature parity + public docs + agent grounding +
per-agent backing. The seven-agent pipeline runs on-device end-to-end
(`swift run aicoscientist "<goal>" --run`), with opt-in `--tools`
grounding (arXiv/PubMed/web) and per-role hosted backing
(`--agent-model role=id`, or the app's Providers tab). Verified on macOS
and on iPhone. M0–M7 landed.

## Last shipped

- **M17 — iCloud sync (SwiftData + CloudKit).** Real team signing
  (`G98TZJ75HL`) + per-app iCloud/CloudKit entitlements; `StudyContainer`
  on the CloudKit private DB with a local-first fallback. Both apps build
  signed with the entitlement embedded (auto-provisioned); live two-device
  sync is the one operator-pending check. `ci_post_clone.sh` makes the
  generated project Xcode-Cloud-buildable; all deps public (no auth). See
  `docs/MILESTONE-17-CLOSEOUT.md`.
- **M16 — Study title + body + CRUD parity (CloudKit-ready).** Editable
  `Study.title` (defaults from the goal's first line, independent after),
  shown in the list + context-menu rename; a pure `StudyConfig` (Kit)
  drives a faithful `StudyDocument` round-trip (title + model choices +
  run config), unit-tested; SwiftData model verified CloudKit-ready. See
  `docs/MILESTONE-16-CLOSEOUT.md`. 152 tests / 36 suites; macOS + iOS build.
- **M13–M15 — UX overhaul + iOS.** Per-study Generator/Reviewer selection,
  install/system-aware picker, Advanced run config, results-outcome header,
  iPad-adaptive inspector + on-device hardening. (Plus fixes: surfaced run
  errors, real tournament-rounds control.)
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

The UX overhaul (M13–M15), **M16** (study title/CRUD), and **M17** (iCloud
sync — signing + CloudKit container) shipped. Next in the **studies + sync
arc** (drafted):

- **Operator-pending:** live two-device sync verification for M17 (needs
  two iCloud-signed devices) — the one acceptance not reproducible
  headlessly.
- **M18 — Distributed compute feasibility spike** — research + findings
  doc; no signing needed. *(draft, next to grind)*
- **M18 — Distributed compute feasibility spike** — research + findings
  doc. *(draft)*
- Candidate themes (see `docs/ROADMAP.md`): multi-indicator run progress,
  model registry sync, parity-test harness, native FM tool calling.

## Pointers

- Strategy + themes: `docs/ROADMAP.md`
- Architecture + design: `docs/ARCHITECTURE.md`
- Milestone doc schema: `docs/MILESTONE-TEMPLATE.md`
- Plan the next batch: `.claude/skills/milestone-planner/SKILL.md`
- Deliver the active plan: `.claude/skills/milestone-grinder/SKILL.md`
