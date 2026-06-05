# Milestone 14 Closeout

Date: 2026-06-05

Milestone:

```txt
Run config + results outcome (macOS)
```

## Status

Complete.

## Delivered

### Track A — Run config on the Study (Apps/Shared + Kit wiring)

- `Study` gains `evolutionTopK` (survivors per round) + `tournamentSize`
  (defaulted to the engine defaults; existing studies migrate cleanly).
  `WorkflowRunner` threads them into `EngineConfiguration`.
- `StudyDetailView` gains a collapsed **Advanced** section exposing both
  with plain one-line explanations — the previously-hidden `evolutionTopK`
  (which decides how many hypotheses survive refinement) is now visible and
  adjustable. Tool-steps deferred (the app doesn't run the tool-use loop
  yet, so the control would be inert).

### Track B — Results outcome (AICoScientistKit + Apps/Shared)

- `RunConclusion` + `RunSnapshot.conclusion`
  (`Sources/AICoScientistKit/Engine/RunConclusion.swift`): a pure
  projection of the top-ranked hypothesis + the meta-review synthesis.
  Unit-tested (incl. the empty case).
- `StudyDetailView.outcomeHeader` leads a finished study with the
  **Conclusion** — the top hypothesis (the answer) + top Elo + the
  meta-review synthesis — above the existing tabs, so the outcome is the
  first thing you see, not buried in a ranked list.

## Validation

```txt
swift build                                   # clean on Apple Silicon
swift test                                    # 145 tests / 34 suites green (+2)
xcodebuild … -scheme CoScientistDemo          # macOS app BUILD SUCCEEDED
xcodebuild … -scheme CoScientistApp …iOS Sim  # iOS app BUILD SUCCEEDED (shared views unbroken)
git grep "import MLX" -- '*.swift'            # only AICoScientistMLX (+ Package.swift comment)
git diff --check                              # whitespace clean
```

## Retrospective

What worked:

- The hidden `evolutionTopK` is now a first-class, explained control — the
  operator's "buried magic number" complaint resolved with one stepper +
  one line of copy (`writing-for-interfaces`).
- `RunSnapshot.conclusion` as a pure projection made the outcome header
  trivial and testable; leading with the answer (`swiftui-design-principles`,
  outcome-first) directly fixes "results don't state the outcome."
- Shared views meant iOS inherited both the Advanced section and the
  outcome header and still builds.

What to improve:

- Tool-steps config is deferred until the app enables the tool-use loop
  (carry-forward).
- The outcome header is a simple block; a future pass could link the
  conclusion to its inspector / show the cluster.
- Verified by build, not a launched run.

Carry forward (M15 — iOS):

- Port the M13/M14 redesign to iPhone/iPad (adaptive layout) + on-device
  memory/thermal hardening.
- Plus the standing carry-forwards: `StudyDocument` round-trips
  generator/reviewer + the new config; Apple Foundation Models in the
  picker; tool-steps config when tools are app-enabled; prune unused
  `SettingsStore` fields; the model-registry-sync theme (operator idea —
  see ROADMAP candidate themes).
