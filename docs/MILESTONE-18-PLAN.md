# Milestone 18 Plan

Date: 2026-06-05

Working name:

```txt
Distributed cross-device compute — feasibility spike
```

## Status

Ready.

## Goal

Determine, honestly, whether CoScientist can harness Apple Silicon **across
the user's iCloud-connected devices** (Mac + iPad + iPhone) to run a study
distributed — and if so, how. This is a **research spike**: the deliverable
is a findings document with a feasibility verdict and a recommended path,
not shipped code.

## Context

Operator (2026-06-05): "the capability Apple released for sharing compute
resources across your iCloud connected devices … harness Apple Silicon
across devices to perform studies." It is not established that a public
third-party API exists for arbitrary cross-device compute sharing, so the
responsible first step is to verify what is actually available before
committing build scope. (Spikes are exploratory; this milestone is
deliberately stepped and time-boxed.)

## Usage Scenarios

### Scenario 1: A grounded go/no-go

Expected behavior:

- The team can read one findings doc and know: is cross-device compute
  feasible for this app today, via what API/mechanism, with what
  constraints — or that it isn't, with the closest viable alternative.

## Primary Scope

### Track A — Research + findings doc (docs/)

Investigate and write `docs/SPIKE-distributed-compute.md` covering:

- What Apple exposes (if anything) for cross-device compute among
  iCloud/Continuity devices usable by a third-party app (vs. system-only
  features); cite sources.
- Whether any of it fits running the seven-agent pipeline's model
  inference off-device.
- Alternatives if no first-party API exists: e.g. run a model server on a
  Mac and point the existing `RemoteLanguageModel` at it over the local
  network (Bonjour discovery) — reusing the M7 hosted-backing seam; or
  defer.
- A clear **verdict** (feasible now / partially / not yet) + a recommended
  next milestone (or "defer") with rough scope.

## Definition Of Done

- `docs/SPIKE-distributed-compute.md` exists with: the API survey (cited),
  a feasibility verdict, constraints, and a recommended path (or explicit
  "defer, because …").
- If a viable path is found, a follow-on milestone is drafted from it
  (otherwise the spike records why not).
- No production code change is required by this milestone.
- `swift build` clean; `swift test` green (unchanged — research only).
- `git diff --check` clean.
- M18 tracking + closeout docs land with the final commit.

## Non-Goals

- Implementing distributed compute — that is a future milestone only if
  the spike says it's feasible.
- Any change to the engine/adapters in this milestone.

## Resolved Decisions

- **Local-network fallback scope.** Decided: since no first-party
  cross-device compute API exists, the spike specifies the "Mac as a local
  model server + `RemoteLanguageModel` over Bonjour/NetworkBrowser"
  alternative as the **recommended follow-on milestone** (drafted as M19),
  reusing the M7 hosted-backing seam.

## Risk

- **Inconclusive research.** If public docs are thin, the verdict may be
  "unknown / not public." That is still a valid, useful outcome — record
  it rather than over-claim.

## Scope Class

Small (research). One findings doc + a possible follow-on draft. No code.

Estimated 1–2 commits (the doc + any follow-on draft).
