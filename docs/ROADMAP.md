# Roadmap

The development arc for coscientist-mlx — a native Swift + MLX port of
the AI co-scientist methodology, running local open models on Apple
Silicon. This is the strategic view; per-milestone detail lives in
`docs/MILESTONE-<N>-{PLAN,TRACKING,CLOSEOUT}.md`, and the immediate
next step in `docs/PROJECT-DEVELOPMENT-SNAPSHOT.md`.

## Current Position

**Hybrid routing, feature-parity, public docs.** The full seven-agent
pipeline runs on-device end-to-end, with schema-constrained decoding,
embedding-based proximity clustering, per-stage backend routing
(on-device MLX and/or a hosted OpenAI-compatible judge), demo apps
(macOS + iOS), a curated model catalog, and a DocC site published to
GitHub Pages.

M0–M5 shipped as numbered milestones (below). The work after M5 — the
CLI, hybrid routing, model catalog, demo apps, and docs — shipped as
feature PRs rather than numbered milestones. The milestone loop
(`milestone-planner` → `milestone-grinder`) is now in use: **M6** (agent
tool-use loop), **M7** (hosted per-agent backing), and **M8** (hypothesis
selection + inspector), **M9** (transparent activity), and **M10**
(Foundation Models backend), and **M11** (batched reflection) have landed
— the M6–M11 batch is complete. Run `milestone-planner` to scope the next
arc.

Agents can now ground hypothesis generation and reflection in real
sources by calling research tools (arXiv, PubMed, web) through a
provider-agnostic tool-use loop — opt-in via the CLI `--tools` flag,
with the default path unchanged.

## Foundations (non-negotiable)

These constrain every milestone. A plan that violates one is rejected
at planning time.

- **Protocol-only domain layer.** `AICoScientistKit` (Core, Agents,
  Engine, Embeddings) depends only on protocols (`LanguageModel`,
  `StructuredDecoder`, `EmbeddingModel`). The engine is MLX-free and
  unit-testable.
- **MLX quarantine.** Every `import MLX*` lives only under
  `Sources/AICoScientistMLX/`. Adapters implement the protocol seams;
  the CLI routes per stage (Dependency Inversion).
- **Genuine TDD/BDD.** Behaviour is driven by tests written first.
  Unit tests use a mock backend — no GPU, no downloads. Real-model
  runs are a separate, opt-in integration target / CI GPU runner.
- **Clean Code, Clean Architecture, SOLID.** Single-responsibility
  agents; failures are recorded (`AgentError`), never crash the run.
- **Local-first.** On-device is the default; remote is an optional
  hybrid judge, never a requirement.

## Milestone Outline

### Completed

- **M0 — Scaffold.** SPM package, targets, MLX deps, swift-log, CI
  (build + test on macOS Apple Silicon).
- **M1 — Inference core.** Quantized model loading, `LanguageModel` +
  `ModelActor`, plain-text generation end-to-end on Apple Silicon.
- **M2 — Structured output.** Typed `JSONSchema`, schema-constrained
  decoding, validate + bounded repair-retry fallback.
- **M3 — Domain + agents.** `Hypothesis`, Elo, all seven system
  prompts ported; typed, schema-constrained output per agent.
- **M4 — Engine.** `CoScientistEngine` actor — full phase pipeline +
  iteration loop + metrics + run persistence. Workflow-shape parity
  with the Python reference.
- **M5 — Embedding proximity.** MLX embeddings + clustering
  (`EmbeddingProximityAnalyzer`) replacing the LLM proximity agent.
- **M6 — Agent tool-use loop.** Provider-agnostic ReAct loop
  (`GroundedDecoder`) + research tools (arXiv, PubMed, web) wired into
  Generation + Reflection via routing; CLI `--tools`. First loop
  milestone. See `docs/MILESTONE-6-CLOSEOUT.md`.
- **M7 — Hosted per-agent model backing.** Model discovery
  (`RemoteModels.list`) + `RoleBackend`/`RoleDecoderRouter.backed`; CLI
  `--agent-model`/`--list-remote-models`; app presets + per-agent pickers.
  See `docs/MILESTONE-7-CLOSEOUT.md`.
- **M8 — Hypothesis selection + inspector.** Pure `HypothesisDetail` +
  `GraphSelection` (Kit); selectable results list + tappable graph nodes
  driving a shared inspector (macOS). See `docs/MILESTONE-8-CLOSEOUT.md`.
- **M9 — Transparent activity.** `ActivityEvent` + persisted
  `RunSnapshot.activity` (Kit); rich feed with per-phase icons, counts,
  and a sticky Elo sparkline (macOS). See `docs/MILESTONE-9-CLOSEOUT.md`.
- **M10 — Foundation Models backend.** Gated `AICoScientistFoundationModels`
  adapter (`LanguageModelSession`) + pure `InferenceBackend` resolver; CLI
  `--backend` + app picker. See `docs/MILESTONE-10-CLOSEOUT.md`.
- **M11 — Batched reflection.** `BatchReflectionAgent` reviews the whole
  pool in one decode (O(N)→1 reflection calls), backend-agnostic. Re-scoped
  from cache-reuse/quant-tiers. See `docs/MILESTONE-11-CLOSEOUT.md`.
- **M12 — Shared app core + iOS (iPhone) parity.** Cross-platform model +
  views extracted to `Apps/Shared`; the full demo (Studies, run, results +
  inspector, activity, Settings, charts, graph, export) builds and runs on
  iOS. See `docs/MILESTONE-12-CLOSEOUT.md`.
- **M13 — Model selection control-flow (macOS).** Per-study Generator +
  Reviewer (each on-device | hosted) via `StudyRouting`; install/system-aware
  picker surfacing `docs/MODELS.md` strengths + device-RAM fit; Settings
  slimmed to providers + downloads. See `docs/MILESTONE-13-CLOSEOUT.md`.
- **M14 — Run config + results outcome (macOS).** Survivors (`evolutionTopK`)
  + tournament rounds exposed in a Study Advanced section; a results header
  that states the conclusion (top hypothesis + meta-review). See
  `docs/MILESTONE-14-CLOSEOUT.md`.
- **M15 — iOS.** The M13/M14 redesign on iPhone/iPad: size-class-adaptive
  inspector + on-device memory/thermal hardening (`RunGuard`). See
  `docs/MILESTONE-15-CLOSEOUT.md`. (Plus fixes: persisted/surfaced run
  errors, and a real tournament-rounds control.)

### Shipped post-M5 as feature PRs (pre-loop)

Delivered ad-hoc before the milestone loop was adopted; folded into the
roadmap for continuity:

- CLI + feature-parity outputs; per-phase timing + interaction transcript.
- Per-stage **DecoderRouting** (DIP) + remote `LanguageModel` adapter
  (`AICoScientistRemote`) → CLI hybrid (local generation + remote judge).
- Repair-retry telemetry; `<think>`-block stripping before JSON extraction.
- Curated model catalog with pinned revisions + source policy + selection.
- macOS + iOS demo apps (unified under `Apps/`); on-device iPhone spike.
- Public README, DocC site → GitHub Pages, architecture/pipeline diagrams.
- CI: MLX/Metal compile guard + runtime inference guard on a self-hosted
  GPU runner.

### Upcoming (themes — sequenced by the planner)

The UX overhaul (M13–M15) is delivered. Next: a **studies + sync arc**
(`milestone-planner`, 2026-06-05):

- **M16 — Study title + body + CRUD parity.** Editable title distinct from
  the goal/body; full create/rename/delete on both apps; faithful
  `StudyDocument` round-trip; CloudKit-ready model. *(draft, next to grind)*
- **M17 — iCloud sync (SwiftData + CloudKit).** Studies sync across the
  user's devices via the private CloudKit DB. Requires real team signing
  (team `G98TZJ75HL`, per the Khaos Machine distro) + an iCloud container.
  *(draft)*
- **M18 — Distributed cross-device compute (feasibility spike).** Research
  whether Apple Silicon across iCloud devices can run studies distributed;
  a findings doc + verdict, no code commitment. *(draft)*

Candidate themes (not yet drafted):

- **Multi-indicator run progress.** Replace the single overloaded progress
  bar with stacked indicators (segmented / radial / standard / charts /
  custom SwiftUI) conveying activity + phase progress (operator idea,
  2026-06-05).
- **Model registry sync.** A synchronizable JSON model registry hosted on
  the repo / GitHub Pages, so model options + research update without a
  new build (operator idea).
- **Parity test harness.** Run a fixed research goal through both this
  port and the Python reference; compare structure/quality.
- **Native Foundation Models tool calling.** Bridge `AgentTool` →
  FM `Tool` (carry-forward from M10; today FM uses the M6 text loop).
- *(Add new themes here as the vision evolves.)*

## How the loop works

1. **Plan** — `milestone-planner` reviews history (recent closeouts +
   carry-forward), this roadmap, the foundations, and the snapshot,
   settles strategic decisions with the operator, and drafts one or more
   `MILESTONE-<N>-PLANNING-DRAFT.md` files.
2. **Grind** — `milestone-grinder` promotes a draft to `PLAN`, delivers
   it via TDD (commit + push often), writes `TRACKING` + `CLOSEOUT`,
   then refreshes this roadmap + the snapshot and drafts the next.

Next number = `max(<N> across docs/MILESTONE-<N>-*.md) + 1`, falling
back to the highest completed milestone in this outline + 1 when no
milestone docs exist yet.
