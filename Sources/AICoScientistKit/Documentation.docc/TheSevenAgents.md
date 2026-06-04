# The Seven Agents

The pipeline, and what each agent contributes to the *generate → debate → evolve* loop.

## Overview

Every agent conforms to ``Agent``: it owns a role (a `systemPrompt`) and a way to turn a
typed `Input` into a user prompt. Decoding the model's response into the agent's
`Output` is handled uniformly by ``SchemaConstrainedDecoding``, so agents carry no
inference or parsing logic — they are added by conformance, not by editing a switch.

``CoScientistEngine`` runs them in the shape established by the reference: an initial
pass, then an N-times refinement loop.

![The seven-agent pipeline: an initial generation, reflection, ranking, and tournament pass, then an N-times loop of meta-review, evolution, reflection, ranking, tournament, and proximity clustering.](pipeline)

## The roles

### Generation

``GenerationAgent`` proposes novel, testable hypotheses for the research goal. Output:
``GeneratedHypotheses`` (a batch of ``GeneratedHypothesis`` with justifications).

### Reflection

``ReflectionAgent`` peer-reviews a single hypothesis, scoring it across six criteria —
scientific soundness, novelty, relevance, testability, clarity, and impact
(``ReviewScores``) — and returns a ``HypothesisReview``.

### Ranking

``RankingAgent`` orders hypotheses by a composite quality score
(``RankedHypotheses``). This sets the initial order; Elo (below) is the authoritative
final ranking.

### Tournament

``TournamentAgent`` judges pairwise matches (``TournamentJudgment``). The engine runs
`3·N` random matches and applies standard Elo updates (k = 24), driving self-play
ranking — the test-time-compute idea at the heart of the paper.

### Meta-review

``MetaReviewAgent`` synthesizes insights across all reviews into strategic guidance
(``MetaReview``, including a ``ProcessAssessment``) that steers the next evolution round.

### Evolution

``EvolutionAgent`` refines the top-k hypotheses using review feedback and meta-review
insights, returning an ``EvolvedHypothesis`` with an explicit change log
(``Refinement`` entries).

### Proximity

``ProximityAgent`` is the LLM-based clustering path (parity/fallback). In production the
engine prefers the embedding-based ``EmbeddingProximityAnalyzer`` — see <doc:Architecture>.

## The Elo lifecycle

Each ``Hypothesis`` starts at an Elo of 1200. Tournament outcomes update ratings via
``Hypothesis`` Elo helpers; the final ``WorkflowResult/topRankedHypotheses`` is ordered
by Elo, with review score as the tie-breaker and the initial seed.
