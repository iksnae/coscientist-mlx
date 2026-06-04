# Component registry — coscientist-mlx explainer

The React components a builder agent must implement (or that must already exist in the
Remotion project) for `pipeline-explainer.spec.md`. Builtins (AbsoluteFill, Sequence,
Series, Img, Audio) are assumed and not listed.

All timing is driven by `useCurrentFrame()` + `interpolate()` + `spring()` — never CSS
transitions.

### HeroMark

Animated Apple-Silicon chip emitting a swarm of agent nodes (the README hero motif).

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
