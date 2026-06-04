---
name: milestone-grinder
description: Run the coscientist-mlx milestone delivery loop end-to-end — execute the current docs/MILESTONE-<N>-PLAN.md via TDD until the Definition of Done passes, write the closeout, draft the next planning artifact, then update docs/ROADMAP.md + docs/PROJECT-DEVELOPMENT-SNAPSHOT.md and promote the next planning draft to PLAN. Encodes the working loop "iterate via TDD until the milestone lands and is properly closed out, commit + push often" → "great work, update roadmap + snapshot + finalize next plan" → repeat. Two modes — stepped (default, pauses between phases for confirmation) and auto (chains phases, halts on TDD exhaustion / DoD failure / max-cycles). Use when the operator says "grind the milestone", "run the milestone loop", "/milestone-grinder", or asks to continue the iterate-close-promote cycle. Do NOT use to start a brand-new milestone with no PLANNING-DRAFT (scope first with milestone-planner), to skip closeout writing, or on a plan whose Status reads Blocked.
---

# milestone-grinder

The coscientist-mlx milestone delivery loop, encoded — the deterministic
entry point for the iterate-close-promote cycle. This skill is
self-contained; the milestone doc schema it reads and writes lives in
[`docs/MILESTONE-TEMPLATE.md`](../../../docs/MILESTONE-TEMPLATE.md).

Project ground rules this loop enforces (the **foundations** in
[`docs/ROADMAP.md`](../../../docs/ROADMAP.md)):

- Protocol-only domain layer; every `import MLX*` quarantined to
  `Sources/AICoScientistMLX/`.
- Genuine TDD — failing test first, mock backend, no GPU/downloads in
  the default `swift test` path.
- Clean Code / Clean Architecture / SOLID; failures recorded, never
  crash the run.

## When to invoke

The operator says any of:

- "grind the milestone" / "run the milestone loop" / "/milestone-grinder"
- "continue to iterate (via TDD) until this milestone lands and is properly closed out, commit + push often"
- "great work! update roadmap, project development snapshot, finalize next milestone plan"
- "auto-grind the next N milestones"

Detect the active milestone as the highest-numbered
`docs/MILESTONE-<N>-PLAN.md` that does **not** have a matching
`docs/MILESTONE-<N>-CLOSEOUT.md`. Override only if the operator names a
specific milestone. If no PLAN exists, stop — run `milestone-planner`
first (this skill refuses to start a milestone with no PLANNING-DRAFT to
promote).

## Phase 1 — Deliver

Active milestone: N. Plan: `docs/MILESTONE-N-PLAN.md`.

1. **Read the plan.** Confirm `Status` is not `Blocked` and every
   Definition of Done bullet is measurable. If unmeasurable → halt and
   surface the specific bullet; do not guess intent.
2. **Open `docs/MILESTONE-N-TRACKING.md`** (scaffold from the template
   if missing). Set Status `In progress`, fill the start date.
3. **For each Primary Scope track (A, B, C, …):**
   1. Write the failing test first (mock backend — no GPU, no model
      download).
   2. Implement until the test passes. Keep `import MLX*` out of
      `AICoScientistKit` / `AICoScientistRemote` — adapter layer only.
   3. Run the validators: `swift build` then `swift test`. Run
      `git diff --check` before committing.
   4. Commit with a scope-tagged message matching the repo style —
      `M<N>: <one-liner>` for milestone work, or the conventional
      `feat(scope): … (M<N>)` / `refactor(scope): …` form seen in
      `git log`. One concern per commit.
   5. **Push.** Every commit, every time. "commit + push often" is
      non-negotiable — it preserves the bisect property.
   6. **Append to `docs/MILESTONE-N-TRACKING.md`** — Acceptance row(s)
      moved to `Done` with an evidence pointer; Validation Log row with
      the commit SHA + outcome.
4. **When all DoD bullets pass:**
   - Write `docs/MILESTONE-N-CLOSEOUT.md` against the template:
     `Status: Complete` / `Delivered` / `Validation` / `Retrospective`
     (incl. carry-forward).
   - Set the TRACKING Status to `Complete`; every Acceptance row `Done`.
   - Scaffold `docs/MILESTONE-(N+1)-PLANNING-DRAFT.md` from the
     PLANNING-DRAFT skeleton in `docs/MILESTONE-TEMPLATE.md`. Populate
     `Goal` and `Context` from N's retro carry-forward; leave the rest
     for Phase 2 (or for `milestone-planner`).
   - Commit both: `M<N>: close out + draft M<N+1>`. Push.

**Stepped mode (default): end here.** Surface to the operator. The
follow-up "great work, update roadmap…" enters Phase 2.

**Auto mode: continue to Phase 2 without a gate.**

## Phase 2 — Promote

1. **Update `docs/ROADMAP.md`:**
   - Move N into the "Completed" milestone outline with a one-sentence
     summary from the retro and a link to its closeout.
   - Refresh "Current Position" to reflect what N delivered.
   - If N+1 introduces a new theme, add or update it under "Upcoming
     (themes)".
2. **Update `docs/PROJECT-DEVELOPMENT-SNAPSHOT.md`:**
   - Bump the snapshot date to today.
   - "Last shipped" → N's closeout link.
   - "Next in flight" → N+1's planning draft (about to be promoted).
3. **Promote N+1:**
   - Open `docs/MILESTONE-(N+1)-PLANNING-DRAFT.md`. Resolve every `[?]`
     open question and every risk. Write a concrete "Primary Scope
     (Execution Order)" against carry-forward items + any new
     ROADMAP-theme intent.
   - Rename in-place to `docs/MILESTONE-(N+1)-PLAN.md`. Set
     `Status: Ready`.
   - Scaffold an empty `docs/MILESTONE-(N+1)-TRACKING.md`.
4. **Commit and push:** `docs: promote M<N+1> plan; roadmap + snapshot
   refreshed` (match the repo's `docs:` message style — see
   `git log --oneline | grep -i promote`).

**Stepped mode: end here.** The next "grind the milestone" invocation
runs Phase 1 on the just-promoted plan.

**Auto mode + cycles remaining: advance N → N+1, re-enter Phase 1.**

## Halt conditions

Halt and return control to the operator on any of:

- **TDD exhaustion** — three consecutive failed implementations on the
  same track without making the failing test pass.
- **Validator rejection** — `swift build` or `swift test` hard-fails and
  can't be fixed within the track's scope.
- **Foundation violation** — an `import MLX*` would have to land outside
  `Sources/AICoScientistMLX/` to satisfy the plan. Halt; the plan is
  wrong, not the code.
- **Plan ambiguity** — a DoD bullet is unmeasurable, or Primary Scope
  references a file/symbol/target that doesn't exist.
- **Broken main** — `swift build` against `origin/main` fails at the
  start of any phase. Halt; require clean main before resuming.
- **Max cycles reached** (auto mode).
- **Manual interrupt** in conversation.

On halt, write the exact pending next step to the conversation so
re-invocation can pick up cleanly. State is fully reconstructable from
disk (PLAN + TRACKING) — no in-memory continuation needed.

## Mode selection

Default to **stepped** unless the operator explicitly says "auto",
"unattended", "overnight", or passes `--auto` / `--max-cycles`.

Auto is for known-tractable plans you don't want to gate. Exploratory
plans ("investigate X") will halt within minutes; stay in stepped.

## Verification (per cycle)

Before declaring a cycle complete, confirm:

- `docs/MILESTONE-N-CLOSEOUT.md` exists; `Status: Complete`; the
  Validation section lists `swift build` + `swift test` (+ any
  opt-in real-model run) with green outcomes.
- `docs/MILESTONE-N-TRACKING.md` Acceptance table is all `Done`.
- `git log` shows incremental scope-tagged commits across Phase 1, each
  pushed.
- `import MLX*` appears only under `Sources/AICoScientistMLX/`
  (`git grep -l 'import MLX' Sources/` shows nothing outside it).
- After Phase 2: `docs/ROADMAP.md` reflects N completed + N+1 in flight;
  `docs/PROJECT-DEVELOPMENT-SNAPSHOT.md` bumped to today;
  `docs/MILESTONE-(N+1)-PLAN.md` exists, `Status: Ready`, no `[?]`
  markers remaining.

## Failure modes

- **Skipping the closeout** — the loop's state machine depends on it.
  Even a one-paragraph retro counts.
- **Squashing commits** — defeats the "commit + push often" bisect
  property. Many small commits per track.
- **Letting `import MLX*` leak into the domain layer** — the single
  most damaging regression; it breaks the mock-backed test path that
  makes the whole engine verifiable. Treat as a hard DoD failure.
- **Skipping the failing-test-first step** — tests written after the
  code aren't TDD and routinely miss the behaviour the plan promised.
- **Editing ROADMAP.md or PROJECT-DEVELOPMENT-SNAPSHOT.md during
  Phase 1** — those are Phase 2's artifacts. Cross-phase edits create
  merge friction with parallel work.
- **Promoting a draft with unresolved `[?]` markers** — Phase 2 must
  resolve every open question before the rename. If unresolvable, halt.
- **Running auto on an exploratory plan** — auto presumes a concrete
  DoD. Stay stepped until the plan is concrete.
