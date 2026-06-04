---
name: milestone-planner
description: Plan the next batch of coscientist-mlx milestones — review the history (recent closeouts + carry-forward), the roadmap (themes, current position), the architecture/foundations (vision + constraints), and the snapshot (next-in-flight), take any operator intention as input, then interact with the operator via AskUserQuestion to settle the strategic decisions and draft one or more docs/MILESTONE-<N>-PLANNING-DRAFT.md files that conform to docs/MILESTONE-TEMPLATE.md and are ready for milestone-grinder to promote. The upstream complement to milestone-grinder, which refuses to start a milestone with no PLANNING-DRAFT. Use when the operator says "plan the next milestones", "scope the next arc", "draft the next batch", or wants to turn an intention/roadmap direction into grindable plans. Do NOT use it to execute or promote a plan (use milestone-grinder), to write a delivered milestone's closeout (grinder owns that), or to invent scope with no roadmap/vision/operator signal.
---

# milestone-planner

The upstream half of the coscientist-mlx milestone loop: turn a
vision/roadmap intention into a **batch of grindable milestone drafts**,
with the strategic decisions settled through `AskUserQuestion` first.
The grinder delivers, closes, and auto-drafts the single next milestone;
this skill is the deliberate, operator-led, plan-a-batch-ahead case.

This skill is self-contained. Drafts conform to
[`docs/MILESTONE-TEMPLATE.md`](../../../docs/MILESTONE-TEMPLATE.md);
[`milestone-grinder`](../milestone-grinder/SKILL.md) Phase 2 promotes a
draft to PLAN. Never promote, execute, or close here.

## Inputs (read before drafting)

- **Operator intention** (primary signal) — what the operator wants next.
- **History** — recent `docs/MILESTONE-<N>-CLOSEOUT.md` retrospectives,
  especially their carry-forward bullets.
- **Direction** — `docs/ROADMAP.md`: Current Position + Upcoming themes.
- **Vision + constraints** — `docs/ARCHITECTURE.md` (design, milestone
  list, risks) and the **Foundations** in `docs/ROADMAP.md`.
- **Next-in-flight** — `docs/PROJECT-DEVELOPMENT-SNAPSHOT.md`.

Next number = `max(<N> across docs/MILESTONE-<N>-*.md) + 1`, falling
back to the highest completed milestone in `docs/ROADMAP.md` + 1 when no
milestone docs exist yet (the loop is new — M0–M5 landed; the first
drafted milestone is **M6**).

## Workflow (summary)

1. **Read the state** (inputs above).
2. **Synthesize candidates** — for each: goal · the signal it traces to
   (operator intention / carry-forward / roadmap line) · rough scope
   class · which layer it touches (AICoScientistKit / AICoScientistMLX /
   AICoScientistRemote / CLI). Drop any candidate with no signal or that
   duplicates an in-flight plan.
3. **Settle decisions via `AskUserQuestion`** — batch theme, size,
   sequencing, scope class per milestone, carry-forward selection, hard
   non-goals. Don't draft until theme/size/sequencing are settled.
4. **Write the drafts** — one `MILESTONE-<N>-PLANNING-DRAFT.md` per
   milestone, in exact template section order, dependency-sequenced,
   each independently shippable, DoD measurable (and including the
   standing rows: failing-test-first, `swift build` + `swift test`
   green, `import MLX*` adapter-only, `git diff --check` clean, tracking
   + closeout land with the final commit). Only genuine delivery-time
   unknowns stay as `[?]`.
5. **Self-check** — template-shaped, `Status: Draft`, measurable DoD,
   scope references real targets/files, no strategic decision buried as
   `[?]`, dependency-ordered. Report each draft + the settled decisions
   to the operator.

## Standing rules

- A draft earns its place only if it traces to an operator intention, a
  carry-forward item, or a roadmap line — **no signal, no milestone.**
- Strategic scope is the operator's call: surface it via
  `AskUserQuestion`. Open Questions are for delivery-time unknowns, not
  deferred strategic decisions.
- **Reject at planning time any candidate that violates the
  foundations** — chiefly: `import MLX*` outside the adapter layer, IO
  or model loading threaded into the protocol-only domain, or making a
  remote backend a hard requirement (local-first is non-negotiable).
- Keep each milestone independently shippable and small enough that the
  grinder can land it in many small commits.
