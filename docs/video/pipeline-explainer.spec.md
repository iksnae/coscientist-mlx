---
composition: PipelineExplainer
fps: 30
duration_frames: 750
scenes:
  - name: hook
    duration_frames: 90
  - name: initial-pass
    duration_frames: 180
  - name: refinement-loop
    duration_frames: 240
  - name: result
    duration_frames: 150
  - name: closing
    duration_frames: 90
---

# Clip: coscientist-mlx — the AI co-scientist pipeline

A ~25-second explainer (30 fps, 750 frames, 1920×1080 landscape) of the
*generate → debate → evolve* loop, matching `docs/assets/pipeline.png` and the README.

> Status: **spec only** — no Remotion project is checked in yet. To build, scaffold a
> Remotion app, implement the components in `component-registry.md`, translate each scene
> below into `src/compositions/PipelineExplainer/scenes/Scene*.tsx`, and render with the
> `remotion-render` skill to `docs/assets/overview.mp4`.

## Source script

`docs/ARCHITECTURE.md` §1 (pipeline) + README "The pipeline".

## Components used

- `HeroMark`: chip-emitting-swarm mark, props `{ frame, scale }`
- `TitleCard`: title + subtitle lockup, props `{ title, subtitle, frame, range }`
- `AgentNode`: labeled pipeline node, props `{ label, role, frame, range }`
- `FlowArrow`: animated connector, props `{ frame, range }`
- `LoopBadge`: "× N" loop badge, props `{ frame, range }`
- `EloBar`: animated ranking bars, props `{ frame, range }`
- `ResultPanel`: top-hypotheses panel, props `{ frame, range }`
- `RouteBadge`: local/remote pill, props `{ kind, frame, range }`
- `CaptionBar`: monospace chyron, props `{ text, frame, range }`
- `RepoFooter`: closing card, props `{ frame, range }`

## Scene 1 — hook (frames 0–90)

On a near-black canvas the `HeroMark` fades up: an Apple-Silicon chip whose glow blooms
into a constellation of agent nodes. The title lockup resolves, then a one-line promise.

Render:

  <HeroMark frame={frame} scale={spring({frame, fps, config: {damping: 14}})} />
  <TitleCard title="coscientist-mlx" subtitle="an AI co-scientist, on Apple Silicon" frame={frame} range={[48, 60]} />
  <CaptionBar text="generate · debate · evolve" frame={frame} range={[74, 90]} />

```typescript
const BEATS = {
  HERO_FADE_IN_START: 0,
  HERO_FADE_IN_END: 14,
  CHIP_GLOW_PULSE: 22,
  SWARM_EMERGE_START: 26,
  SWARM_EMERGE_END: 44,
  TITLE_IN_START: 48,
  TITLE_IN_END: 60,
  SUBTITLE_IN: 66,
  CAPTION_IN: 74,
  HOLD_END: 89,
} as const;
```

## Scene 2 — initial-pass (frames 90–270)

The four initial-pass agents arrive left-to-right, each connected by a `FlowArrow`:
Generation proposes, Reflection peer-reviews, Ranking orders, Tournament runs Elo
self-play. `EloBar`s rise and settle as the tournament resolves.

Render:

  <AgentNode label="Generation" role="propose hypotheses" frame={frame} range={[90, 102]} />
  <FlowArrow frame={frame} range={[116, 120]} />
  <AgentNode label="Reflection" role="peer review" frame={frame} range={[120, 132]} />
  <FlowArrow frame={frame} range={[148, 152]} />
  <AgentNode label="Ranking" role="score & order" frame={frame} range={[152, 164]} />
  <FlowArrow frame={frame} range={[180, 184]} />
  <AgentNode label="Tournament" role="Elo self-play" frame={frame} range={[184, 196]} />
  <EloBar frame={frame} range={[204, 226]} />
  <CaptionBar text="3·N pairwise matches, k=24" frame={frame} range={[244, 268]} />

```typescript
const BEATS = {
  GEN_NODE_IN_START: 90,
  GEN_NODE_IN_END: 102,
  GEN_CAPTION_IN: 108,
  ARROW_GEN_REF: 116,
  REF_NODE_IN_START: 120,
  REF_NODE_IN_END: 132,
  REF_SCORE_TICK: 140,
  ARROW_REF_RANK: 148,
  RANK_NODE_IN_START: 152,
  RANK_NODE_IN_END: 164,
  RANK_SORT_ANIM: 172,
  ARROW_RANK_TOUR: 180,
  TOUR_NODE_IN_START: 184,
  TOUR_NODE_IN_END: 196,
  ELO_BARS_IN: 204,
  ELO_BARS_SETTLE: 226,
  CAPTION_SWAP: 244,
  HOLD_END: 268,
} as const;
```

## Scene 3 — refinement-loop (frames 270–510)

A `LoopBadge` frames the round. Meta-Review synthesizes, Evolution refines the top-k
(with a diff highlight), then Reflection / Ranking / Tournament re-run and the `EloBar`s
reshuffle. Proximity forms embedding clusters, and a back-arrow shows the loop repeating.

Render:

  <LoopBadge frame={frame} range={[270, 276]} />
  <AgentNode label="Meta-Review" role="synthesize insights" frame={frame} range={[276, 288]} />
  <FlowArrow frame={frame} range={[296, 300]} />
  <AgentNode label="Evolution" role="refine top-k" frame={frame} range={[300, 312]} />
  <AgentNode label="Reflection" role="re-review" frame={frame} range={[336, 348]} />
  <AgentNode label="Ranking" role="re-rank" frame={frame} range={[352, 364]} />
  <AgentNode label="Tournament" role="Elo self-play" frame={frame} range={[372, 384]} />
  <EloBar frame={frame} range={[392, 412]} />
  <FlowArrow frame={frame} range={[412, 416]} />
  <AgentNode label="Proximity" role="embedding clusters" frame={frame} range={[416, 436]} />

```typescript
const BEATS = {
  LOOP_BADGE_IN: 270,
  LOOP_BADGE_SETTLE: 274,
  META_NODE_IN_START: 276,
  META_NODE_IN_END: 288,
  META_THEMES_TICK: 292,
  ARROW_META_EVO: 296,
  EVO_NODE_IN_START: 300,
  EVO_NODE_IN_END: 312,
  EVO_DIFF_HIGHLIGHT: 322,
  EVO_REFINE_LABEL: 326,
  ARROW_EVO_REF: 330,
  REF2_NODE_IN: 336,
  REF2_SCORE_TICK: 346,
  RANK2_NODE_IN: 352,
  RANK2_SORT_ANIM: 362,
  TOUR2_NODE_IN: 372,
  TOUR2_MATCH_FLASH: 382,
  ELO_RESHUFFLE: 392,
  ELO_SETTLE: 404,
  ARROW_TOUR_PROX: 412,
  PROX_NODE_IN_START: 416,
  PROX_CLUSTERS_FORM: 436,
  PROX_CLUSTERS_SETTLE: 452,
  LOOP_ARROW_BACK: 468,
  LOOP_COUNTER_TICK: 484,
  HOLD_END: 508,
} as const;
```

## Scene 4 — result (frames 510–660)

A `ResultPanel` lists the top-ranked hypotheses with Elo labels. `RouteBadge`s reveal the
deployment story: every stage runs local on-device, or reflection + tournament can route
to a remote judge for the hybrid split.

Render:

  <ResultPanel frame={frame} range={[510, 524]} />
  <RouteBadge kind="local" frame={frame} range={[572, 584]} />
  <RouteBadge kind="remote" frame={frame} range={[588, 600]} />
  <FlowArrow frame={frame} range={[600, 612]} />
  <CaptionBar text="local · private · offline — or hybrid" frame={frame} range={[628, 658]} />

```typescript
const BEATS = {
  RESULT_PANEL_IN_START: 510,
  RESULT_PANEL_IN_END: 524,
  TOP_HYP_1_IN: 532,
  TOP_HYP_2_IN: 540,
  TOP_HYP_3_IN: 548,
  ELO_LABELS_IN: 558,
  ELO_LABELS_SETTLE: 566,
  LOCAL_BADGE_IN: 572,
  LOCAL_BADGE_PULSE: 580,
  HYBRID_BADGE_IN: 588,
  ARROW_REMOTE: 600,
  REMOTE_JUDGE_PULSE: 612,
  CAPTION_LOCAL_PRIVATE: 628,
  CAPTION_HOLD: 644,
  HOLD_END: 658,
} as const;
```

## Scene 5 — closing (frames 660–750)

The `HeroMark` returns small, the `RepoFooter` shows the repo URL, the DocC docs badge,
and the citation note (Gottweis et al., 2025), then the canvas fades to black.

Render:

  <RepoFooter frame={frame} range={[660, 672]} />
  <HeroMark frame={frame} scale={interpolate(frame, [712, 730], [1, 0.7])} />
  <CaptionBar text="github.com/iksnae/coscientist-mlx" frame={frame} range={[680, 700]} />

```typescript
const BEATS = {
  REPO_FOOTER_IN_START: 660,
  REPO_FOOTER_IN_END: 672,
  DOCS_BADGE_IN: 680,
  URL_UNDERLINE: 686,
  CITATION_IN: 690,
  LICENSE_NOTE: 700,
  CHIP_MARK_RETURN: 712,
  FADE_OUT_START: 730,
  FADE_OUT_END: 748,
} as const;
```
