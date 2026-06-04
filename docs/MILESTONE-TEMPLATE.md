# Milestone Document Template

The canonical schema for milestone planning, tracking, and closeout docs
in coscientist-mlx. The `milestone-planner` skill drafts against the
PLANNING-DRAFT section; `milestone-grinder` promotes it to PLAN, fills
TRACKING during delivery, and writes CLOSEOUT at the end.

**Acceptance-table contract** (the grinder's verification step parses
this exact shape):

- Three columns: `Acceptance` | `Status` | `Evidence`.
- `Status` values: `Done`, `Partial`, `Pending`, `Skipped`, or
  `In progress`. Only `Done` counts as complete.
- The doc-level `## Status` heading reads `Draft`, `In progress`,
  `Closing`, or `Complete`. A milestone is closeable only when the
  Status is `Closing`/`Complete` **and** every acceptance row is `Done`.

When starting a new milestone, copy the relevant section below into
`docs/MILESTONE-<N>-{PLANNING-DRAFT,PLAN,TRACKING,CLOSEOUT}.md` and
fill it in.

---

## `MILESTONE-<N>-PLANNING-DRAFT.md`

```markdown
# Milestone <N> Planning Draft

Date: <YYYY-MM-DD>

Working name:

`​``txt
<Title in Sentence Case>
`​``

## Status

Draft. Not yet promoted to MILESTONE-<N>-PLAN.md.

## Goal

<2–4 sentences. What changes? Why now? What does success look like
when a developer sits down at the next session?>

## Context

<What happened in the prior milestone(s) that motivates this scope?
Which carry-forward signals does this milestone pick up? Be specific
about the prior closeout sections or roadmap themes this addresses.>

## Usage Scenarios

### Scenario 1: <developer- or user-facing flow>

Expected behavior:

- <observable outcome — e.g. a CLI flag, an engine output field>
- <observable outcome>

### Scenario 2: <...>

...

## Primary Scope

### Track A — <short name>

<2–4 sentences. What lands? Which targets / file paths roughly?
Name the layer: AICoScientistKit (domain, MLX-free), AICoScientistMLX
(on-device adapter), AICoScientistRemote (hosted adapter), or
AICoScientistCLI.>

### Track B — <...>

...

## Definition Of Done

- <every acceptance row, written as a one-line claim>
- ...
- New behaviour is driven by a test written first (mock backend, no GPU).
- `swift build` clean; `swift test` green.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`.
- `git diff --check` clean.
- M<N> tracking + closeout docs land with the final commit.

## Non-Goals

- <out of scope, with a one-sentence reason>
- ...

## Open Questions

- **<question>.** <one paragraph of the trade-offs. Lean <answer>.>
- ...

## Risk

- **<risk>.** Mitigate by <plan>.
- ...

## Scope Class

<Small / Medium / Large>. <One sentence justification.>

Estimated <N>–<M> commits per track, ~<total> commits.
```

---

## `MILESTONE-<N>-PLAN.md`

```markdown
# Milestone <N> Plan

Date: <YYYY-MM-DD>

Working name:

`​``txt
<Title>
`​``

## Status

Ready. Promoted from `docs/MILESTONE-<N>-PLANNING-DRAFT.md`.

## Goal

<Same as draft, optionally tightened.>

## Primary Scope (Execution Order)

### Track A — <name>

<Restated for execution. Order optimizes for commit-able wins
early; document the order rationale here.>

### Track B — <...>

...

## Definition Of Done

<Same as draft — every bullet measurable.>

## Non-Goals

<Same as draft.>
```

---

## `MILESTONE-<N>-TRACKING.md`

```markdown
# Milestone <N> Tracking

Date: <YYYY-MM-DD>

Milestone:

`​``txt
<Title>
`​``

## Status

<In progress | Closing | Complete>

## Duration And Usage Tracking

| Field | Value |
| --- | --- |
| Planned start | <YYYY-MM-DD> |
| Actual start | <YYYY-MM-DD> |
| Actual end | <YYYY-MM-DD or TBD> |
| Elapsed | <duration> |
| Scope class | <Small / Medium / Large> |
| Confidence | <Low / Medium / High> |

## Acceptance Tracking

| Acceptance | Status | Evidence |
| --- | --- | --- |
| <one-line acceptance claim>. | Done | <file / test / output pointer> |
| <...>. | Pending | <what's blocking> |

## Validation Log

| Command | Status | Notes |
| --- | --- | --- |
| `swift build` | Passed | Builds clean on Apple Silicon. |
| `swift test` | Passed | <what's covered — mock-backed unit specs> |
| `git diff --check` | Passed | Whitespace clean. |

## Decisions

| Decision | Outcome | Reason |
| --- | --- | --- |
| <decision>. | Accepted / Rejected | <one-paragraph reason> |
```

---

## `MILESTONE-<N>-CLOSEOUT.md`

```markdown
# Milestone <N> Closeout

Date: <YYYY-MM-DD>

Milestone:

`​``txt
<Title>
`​``

## Status

Complete.

## Delivered

### Track A — <name>

<What landed. Targets + file paths. The shape of the change. Honest
about what's NOT in scope despite being adjacent.>

### Track B — <...>

...

## Validation

`​``txt
swift build                         # clean on Apple Silicon
swift test                          # all mock-backed specs green
<other relevant commands — e.g. an opt-in real-model run>
`​``

## Retrospective

What worked:

- <one-line observation>
- ...

What to improve:

- <one-line observation>
- ...

Carry forward (M<N+1> candidates):

- <next milestone candidate>
- ...
```

---

## Notes

- **Unit tests use the mock backend** — no GPU, no model downloads.
  Real-model behaviour lives in the opt-in integration target / the
  CI GPU runner, not the default `swift test` path.
- **The MLX quarantine is a hard invariant.** Any `import MLX*` outside
  `Sources/AICoScientistMLX/` is a DoD failure, not a style nit — it
  breaks the protocol-only domain layer that makes the engine testable.
- The acceptance-table column shape is load-bearing: the grinder's
  per-cycle verification walks `|`-delimited rows and reads the second
  column as Status. Keep the three-column shape.
