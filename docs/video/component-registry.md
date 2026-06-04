# Component registry — coscientist-mlx explainer

The React components a builder agent must implement (or that must already exist in the
Remotion project) for `pipeline-explainer.spec.md`. Builtins (AbsoluteFill, Sequence,
Series, Img, Audio) are assumed and not listed.

All timing is driven by `useCurrentFrame()` + `interpolate()` + `spring()` — never CSS
transitions. Components must match the docs theme (see "Design tokens").

## Design tokens

Mirror `docs/assets/*.mmd` so the video is on-brand with the diagrams:

- `bg` `#070b14` · `text` `#e6edf3` · `line` `#38bdf8` · font `Inter`
- Phase accents: `generation` `#38bdf8` · `reflection` `#22d3ee` · `ranking` `#60a5fa`
  · `tournament` `#a78bfa` · `metaReview` `#f0abfc` · `evolution` `#2dd4bf`
  · `proximity` `#fbbf24` · `io`/`success` `#34d399` · `error` `#f87171`
- Reusable stills via `staticFile()`: `hero.png`, `pipeline.png`, `architecture.png`,
  `decode.png` (copy into the Remotion project's `public/` at build time).

### HeroMark

Animated Apple-Silicon chip emitting a swarm of agent nodes — wraps `hero.png` with a
glow/scale animation (the README hero motif).

- Props: `{ frame: number, scale: number }`

### TitleCard

Centered title + subtitle lockup.

- Props: `{ title: string, subtitle: string, frame: number, range: [number, number] }`

### AgentNode

A labeled pipeline node representing one agent.

- Props: `{ label: string, role: string, frame: number, range: [number, number] }`

### FlowArrow

Animated connector that draws between two nodes.

- Props: `{ frame: number, range: [number, number] }`

### LoopBadge

An "× N" badge framing the refinement loop.

- Props: `{ frame: number, range: [number, number] }`

### EloBar

Animated horizontal bars showing Elo ranking shuffling.

- Props: `{ frame: number, range: [number, number] }`

### ResultPanel

Panel listing top-ranked hypotheses with Elo labels.

- Props: `{ frame: number, range: [number, number] }`

### RouteBadge

A pill marking a stage as local (on-device) or remote (hybrid judge).

- Props: `{ kind: "local" | "remote", frame: number, range: [number, number] }`

### CaptionBar

Monospace caption chyron.

- Props: `{ text: string, frame: number, range: [number, number] }`

### RepoFooter

Closing card with repo URL, docs badge, and citation note.

- Props: `{ frame: number, range: [number, number] }`
