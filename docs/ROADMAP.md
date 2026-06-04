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
(`milestone-planner` → `milestone-grinder`) is now in use: **M6 (agent
tool-use loop + grounded Generation/Reflection)** landed as the first
loop milestone. The next numbered milestone is **M7**.

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

A batch of milestones is drafted and dependency-sequenced after M6
(`milestone-planner`, 2026-06-04):

- **M7 — Hosted per-agent model backing.** Model discovery
  (`GET /models`) + per-role backend assignment; makes the M6 tool-use
  loop reliable by routing tool-using roles to a capable hosted model.
  *(in flight — `MILESTONE-7-PLAN.md`)*
- **M8 — Foundation Models backend.** Apple's native tool calling as an
  optional, availability-gated backend. *(draft)*
- **M9 — Graph selection + details inspector.** Click a node in the
  graph view to inspect its underlying data. *(draft)*
- **M10 — Inference optimization.** Prompt/KV cache reuse + quant tiers.
  *(draft)*

Further out (theme, not yet drafted):

- **Parity test harness.** Run a fixed research goal through both this
  port and the Python reference; compare structure/quality.
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
