# Milestone 26 Planning Draft

Date: 2026-06-05

Working name:

```txt
Inspector + realtime viz polish + accessibility
```

## Status

Draft. Not yet promoted to MILESTONE-26-PLAN.md.

## Goal

Finish the overhaul: a complete **Hypothesis Inspector**, **realtime
visualizations** driven smoothly from the M22 `RunState`, **empty/first-run
states**, and an **accessibility + HIG pass** — with `design-audit` enforcing
token compliance.

## Context

Final milestone of the build batch (after M23 tokens, M24 Results-first +
Configure, M25 Models + shells). The data exists (HypothesisDetail with 6
review scores, lineage, matches; RunState Elo timeline + activity); this
milestone makes the detail + motion + a11y first-class.

## Usage Scenarios

### Scenario 1: Inspect deeply
- Selecting a hypothesis shows its **6 review scores** (scientific soundness,
  novelty, relevance, testability, clarity, impact) as bars, the review
  summary + any safety/ethical note, its **lineage**, and match record.

### Scenario 2: Watch it think
- During a run, the phase breadcrumb, radial gauge, Elo sparkline, and
  Graph/Charts update with smooth, tasteful motion from `RunState`.

### Scenario 3: Accessible + welcoming
- Empty/first-run states guide a new user; Dynamic Type, contrast, and
  VoiceOver work throughout (Elo/scores have descriptive labels).

## Primary Scope

### Track A — Hypothesis Inspector
Build the full inspector from `HypothesisDetail`: 6 review-score bars, review
summary, safety/ethical note (if present), lineage (evolution history),
match record (win/loss). Tokens from M23. (`swift-design`, `swiftui-pro`.)

### Track B — Realtime viz polish
Refine/animate `RunProgressView` + the Graph/Charts lenses from `RunState`
(phase transitions, Elo trend, cluster forming) with tasteful motion (ease,
no bounce). `ChartsView` score-dimension + Elo-over-time; `GraphView`
clustering.

### Track C — Empty + first-run states
Empty studies list, empty results, no-provider, no-models, and a light
first-run hint, via `writing-for-interfaces` + `ContentUnavailableView`.

### Track D — Accessibility + HIG + audit
`swift-design` pass (40 rules): Dynamic Type, contrast (AA), VoiceOver labels
(e.g. "Top hypothesis, rank score 1277, 100 percent win"), focus order, tap
targets. Run `design-audit` and resolve token-compliance findings.

## Definition Of Done

- Inspector shows the full `HypothesisDetail` (6 scores + summary + safety +
  lineage + matches).
- Realtime visualizations animate from `RunState` (verified by build + a
  recorded review pass); Graph/Charts reflect clusters/Elo.
- Empty/first-run states present for the key surfaces.
- Accessibility: Dynamic Type, AA contrast, VoiceOver labels on Elo/scores/
  charts; `design-audit` findings resolved (recorded in closeout).
- Any pure helpers unit-tested; `swift build` clean; `swift test` green;
  macOS + iOS apps build.
- `import MLX*` only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M26 tracking + closeout land with the final commit.

## Non-Goals

- New engine/data (uses existing HypothesisDetail/RunState).
- Ambitious net-new visualizations beyond the IA's lenses (could be a later
  theme); this polishes + animates what exists.
- LAN model offload (M19).

## Open Questions

- **[?]** Motion budget on iOS (thermals/perf): how much continuous
  animation during a run. Lean: animate on state-change transitions, not
  continuous loops; respect Reduce Motion.

## Risk

- **A11y/animation verified by build + review, not live device.** Mitigation:
  follow the swift-design rubric; operator device pass at closeout (also
  closes the M22 live-verification carry-forward).

## Scope Class

Medium.
