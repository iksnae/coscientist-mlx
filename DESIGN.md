# CoScientist — Design System

Single source of truth for the CoScientist visual language. Every hex value,
type size, spacing constant, shadow, and status colour lives here — derived
from the live token source in `Apps/Shared/DesignTokens/`. The companion
files `docs/DESIGN-IA.md` and `docs/DESIGN-WIREFRAMES.md` define the
information architecture and lo-fi structure this system dresses.

---

## Palette

### Raw brand colours

| Token | Hex | sRGB | Role |
|---|---|---|---|
| `deepNavy` | `#070b14` | `rgb(7, 11, 20)` | Primary background (full-screen, window) |
| `elevatedSurface` | `#0e1726` | `rgb(14, 23, 38)` | Elevated surface (cards, sheets, grouped rows) |
| `cyanAccent` | `#22d3ee` | `rgb(34, 211, 238)` | Primary accent (buttons, links, active states, progress) |
| `teal` | `#2dd4bf` | `rgb(45, 212, 191)` | Success / positive / confirmed state |
| `sky` | `#38bdf8` | `rgb(56, 189, 248)` | Informational / highlight |
| `amber` | `#fbbf24` | `rgb(251, 191, 36)` | Warning / attention / pending |
| `offWhite` | `#e6edf3` | `rgb(230, 237, 243)` | Primary body text |

### Semantic role assignments

| Role | Maps to | Usage |
|---|---|---|
| `background` | `deepNavy` | App-wide background |
| `surface` | `elevatedSurface` | Cards, sheets, group rows |
| `accent` | `cyanAccent` | Buttons, links, active, progress |
| `success` | `teal` | Positive / confirmed |
| `warning` | `amber` | Attention / pending |
| `textPrimary` | `offWhite` | Body text |
| `textSecondary` | `offWhite` at 65% opacity | Captions, metadata, placeholders |

### WCAG AA contrast pairs

All ratios measured against the two background surfaces (`deepNavy` and
`elevatedSurface`). WCAG AA requires ≥ 4.5∶1 for normal text and ≥ 3∶1 for
large text (≥ 18 pt or ≥ 14 pt bold). AAA (enhanced) requires ≥ 7∶1 for
normal text.

| Foreground | Background | Ratio | Passes AA? | Passes AAA? |
|---|---|---|---|---|
| `offWhite` (`#e6edf3`) | `deepNavy` (`#070b14`) | **16.7∶1** | ✅ AA | ✅ AAA |
| `offWhite` (`#e6edf3`) | `elevatedSurface` (`#0e1726`) | **15.2∶1** | ✅ AA | ✅ AAA |
| `textSecondary` (65% blend) | `deepNavy` (`#070b14`) | **7.3∶1** | ✅ AA | ✅ AAA |
| `textSecondary` (65% blend) | `elevatedSurface` (`#0e1726`) | **6.6∶1** | ✅ AA | ✗ — large text only for AAA |
| `cyanAccent` (`#22d3ee`) | `deepNavy` (`#070b14`) | **10.9∶1** | ✅ AA | ✅ AAA |
| `cyanAccent` (`#22d3ee`) | `elevatedSurface` (`#0e1726`) | **9.9∶1** | ✅ AA | ✅ AAA |
| `teal` (`#2dd4bf`) | `deepNavy` (`#070b14`) | **10.6∶1** | ✅ AA | ✅ AAA |
| `teal` (`#2dd4bf`) | `elevatedSurface` (`#0e1726`) | **9.7∶1** | ✅ AA | ✅ AAA |
| `amber` (`#fbbf24`) | `deepNavy` (`#070b14`) | **11.8∶1** | ✅ AA | ✅ AAA |
| `amber` (`#fbbf24`) | `elevatedSurface` (`#0e1726`) | **10.8∶1** | ✅ AA | ✅ AAA |
| `sky` (`#38bdf8`) | `deepNavy` (`#070b14`) | **9.2∶1** | ✅ AA | ✅ AAA |
| `sky` (`#38bdf8`) | `elevatedSurface` (`#0e1726`) | **8.4∶1** | ✅ AA | ✅ AAA |

> **Takeaway:** Every semantic colour pair clears WCAG AA with room to spare.
> The `textSecondary`/`elevatedSurface` pair clears AA but falls just short
> of AAA for normal text — keep secondary labels ≥ 14 pt bold or ≥ 18 pt
> when legibility is critical.

---

## Typography

### Type scale

All presets use **SF Pro** (the system font), applied via SwiftUI's
`.font()` modifier. Each preset participates in Dynamic Type — text scales
automatically with the user's preferred reading size.

| Preset | SF Pro size | Weight | Use |
|---|---|---|---|
| `caption2` | 11 pt | Regular | Smallest label (timestamps, progress micro-text) |
| `caption` | 12 pt | Regular | Supporting text (metadata, secondary labels) |
| `callout` | 13 pt | Regular | Slightly-emphasised secondary (inline notes) |
| `body` | 17 pt | Regular | Default reading text (hypothesis body, config fields) |
| `headline` | 17 pt | Semibold | Emphasised body-level (section headers in cards) |
| `title3` | 20 pt | Regular | Smaller title (subsection headers) |
| `title2` | 22 pt | Regular | Medium title (Study title in detail header) |

### Dynamic Type behaviour

- Every preset is a **SwiftUI semantic font** (`Font.caption2`, `Font.body`,
  …), not a fixed-point size. Users who set a larger reading size in
  System Settings will see all text scale proportionally.
- **Do not** use `.font(.system(size: …))` for body text — that bypasses
  Dynamic Type and locks the size.
- For truly fixed labels (e.g. a badge chip at 9 pt), use
  `.font(.system(size: 9, design: .rounded))` sparingly and only when
  Dynamic Type would break the layout.

### Weight emphasis

- **Headline** is the only bold-by-default preset (Semibold). For emphasis
  elsewhere, prefer `.fontWeight(.semibold)` over switching fonts.
- For monospaced content (code, paths, model keys), use
  `.font(.body.monospaced())` to stay within the type scale.

---

## Spacing

### The 8‑point grid

Every spacing value is a multiple of 8. This keeps vertical rhythm
consistent and makes layout predictable across screens.

| Token | Value | Use |
|---|---|---|
| `xs` | 4 pt | Tight inline gaps (icon↔label, badge padding) |
| `sm` | 8 pt | Default inter-item gap (row spacing, stack gaps) |
| `md` | 16 pt | Standard section padding (card insets, group padding) |
| `lg` | 24 pt | Block-level separation (between conclusion and list) |
| `xl` | 32 pt | Major section breaks (header↔body) |
| `xxl` | 48 pt | Page-level margins (root container edge padding) |

### Usage guidance

- **`sm` (8 pt) is the default.** Start there for any gap; escalate only
  when the visual hierarchy demands it.
- Use `xs` (4 pt) only for **inline** spacing — never for padding around a
  card or section.
- `md` (16 pt) is the standard **horizontal inset** for cards and rows.
- `lg`/`xl`/`xxl` separate **semantic blocks**, not individual rows.
- **Never** use odd-numbered spacing (3, 5, 7, 9, …) — it breaks the grid
  and creates visual friction with the 8-pt rhythm.

---

## Elevation

### Shadow presets

Shadows create depth on the deep-navy background. Three tiers only — no
custom blur/offset combinations in views.

| Elevation | Colour | Opacity | Radius | Offset (x, y) | Use |
|---|---|---|---|---|---|
| `low` | Black | 35 % | 3 pt | (0, 1) | Cards, inactive surfaces — subtle lift |
| `medium` | Black | 45 % | 6 pt | (0, 2) | Floating panels, popovers, hover states |
| `high` | Black | 55 % | 12 pt | (0, 4) | Modal overlays, sheets — maximum depth cue |

Apply via view modifiers:

```swift
card.elevationLow()
popover.elevationMedium()
modal.elevationHigh()
```

**Do not** use `.shadow(color:radius:x:y:)` directly — it breaks the tier
system and makes future elevation changes inconsistent.

### Corner radius tiers

| Tier | Value | Use |
|---|---|---|
| `sm` | 4 pt | Subtle rounding — inline elements (chips, badges, status dots) |
| `md` | 8 pt | Standard rounding — cards, rows, list items |
| `lg` | 12 pt | Generous rounding — modals, sheets, prominent surfaces |

**Do not** use `.cornerRadius(6)` or other ad-hoc values. Pick the nearest
tier. If none fits, the need for a new tier should be discussed and
documented here first.

---

## Status

### Draft / Running / Done / Error

Status is mapped through `Theme.status.color(for:)` and the pure-logic
`DesignStatus` enum in `AICoScientistKit`. Views must never hardcode status
colours.

| Status | Colour | Token | Severity | Label |
|---|---|---|---|---|
| `.draft` | Muted white (65%) | `textSecondary` | 0 | Draft |
| `.running` | Cyan | `accent` (`#22d3ee`) | 1 | Running |
| `.done` | Teal | `success` (`#2dd4bf`) | 2 | Done |
| `.error` | System red | `Color.red` | 3 | Error |

### Usage rules

- **Status dots** next to study rows use the semantic colour as the
  foreground fill (circle or capsule).
- **Do not encode meaning in colour alone.** Every status carries a text
  label, an icon, or both — never a bare coloured dot.
- **Severity** (`0`–`3`) drives sort order and badge prominence. Higher
  severity statuses (`.running`, `.error`) may justify a stronger visual
  treatment (pulsing indicator, error banner).
- The `DesignStatus` enum in `Sources/AICoScientistKit/Design/` is the
  single source for label text and severity values — apps consume it
  through `Theme.status` and never redefine labels.

---

## Component

### Styling do's

- **Do** import tokens through the `Theme` namespace:
  ```swift
  Text("Running").foregroundStyle(Theme.color.accent)
  HStack(spacing: Theme.space.Spacing.sm) { … }
  ```
- **Do** use semantic font presets (`Theme.text.body`, `Theme.text.headline`)
  for all text — never raw `.font(.system(size: …))`.
- **Do** apply elevation through the modifier chain
  (`.elevationLow()`, `.elevationMedium()`, `.elevationHigh()`).
- **Do** pick the nearest corner-radius tier (`Theme.space.Radius.md`) for
  any rounded surface.
- **Do** reach for `Theme.status.color(for:)` when colouring status
  indicators — the mapping is centralised and testable.
- **Do** set backgrounds with `Theme.color.background` / `Theme.color.surface`
  so the entire app shares the same dark-navy depth stack.

### Styling don'ts

- **Don't** use raw hex values, `Color(red:green:blue:)`, or `#colorLiteral`
  anywhere in view code.
- **Don't** hardcode spacing integers — `spacing: 8` is banned; use
  `SpacingTokens.Spacing.sm` (or `Theme.space.Spacing.sm`).
- **Don't** bypass Dynamic Type with `.font(.system(size: 14))` for body text.
- **Don't** define ad-hoc shadows — `.shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 2)`
  is banned; use `.elevationLow()` / `.elevationMedium()` / `.elevationHigh()`.
- **Don't** repeat the status→colour mapping in views — one copy lives in
  `Theme.status.color(for:)`.
- **Don't** add new spacing values or corner radii without updating this
  document and the token source files.

### New-view checklist

1. All colours come from `Theme.color.*`.
2. All text styles come from `Theme.text.*`.
3. All spacing values come from `Theme.space.Spacing.*`.
4. All corner radii come from `Theme.space.Radius.*`.
5. All shadows use the `elevation*()` modifiers.
6. All status colours use `Theme.status.color(for:)`.
7. No magic numbers remain.

---

## Image-Generation Prompt Suffix

When design skills (image-generate, mockup rendering, hero-image creation)
produce visual assets for CoScientist, append the following suffix to every
prompt. It encodes the brand's visual identity in language the image model
can interpret:

```
Dark theme scientific macOS/iOS application UI. Deep navy (#070b14) background
with elevated surface cards (#0e1726). Cyan (#22d3ee) accent highlights,
teal (#2dd4bf) success indicators, off-white (#e6edf3) text. SF Pro typography
at native Apple rendering quality. Clean spacing on an 8-point grid, subtle
shadow depth, corner-radius cards. Native SwiftUI look — Apple Human Interface
Guidelines, no Material Design influence, no rounded buttons, no bright white
backgrounds. Dark mode only.
```

To reference this suffix in tool invocations, use the shorthand
**`image.gen`** — each design skill resolves it to the full suffix above.

---

*Last updated: 2026-06-05 · Derived from `Apps/Shared/DesignTokens/` and
`Sources/AICoScientistKit/Design/DesignSemantics.swift`.*
