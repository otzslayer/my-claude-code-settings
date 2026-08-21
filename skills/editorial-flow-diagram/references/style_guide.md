# Style Guide — Editorial Flow Diagram

Read this when you are **hand-authoring** an SVG: a swimlane drawing, a nested
architecture sketch, or a tweak to an already-generated file. Diagrams built
from a spec get all of this applied for you by `scripts/build_diagram.py`.

The goal is calm, editorial, and legible: one warm neutral field, dark charcoal
structure, and a single clay accent used only where it earns attention. The
restraint is the style — resist adding hues.

## Where the numbers live

`scripts/build_diagram.py` holds every hex value, font size, and node dimension
as named constants at the top of the file, under the
`design system` heading. Read them from there rather than from a copy here, and
change them there when the look should change. What follows is the reasoning
those constants encode, which the code cannot state.

## The three node roles

**Terminator** — the flow's start and end. A fully-rounded clay pill, its label
in the on-accent near-white. Never numbered: terminators are not steps, they are
the boundary the steps sit between.

**Process** — a normal step. A near-white rounded rectangle outlined in ink,
title on the upper line and an optional one-line subtitle below it. Numbered
with a clay circle badge on the border the flow does not arrive through: the
left edge in a top-down diagram, the top edge in a left-to-right one.

**Check** — a validation, decision, gate, guard, or approval. The same geometry
as a process node, but filled clay-tint and outlined in clay, with its subtitle
in the darker clay text color. This is the one place the accent does real work,
marking the steps a reader should slow down for. Keep them rare; a diagram where
every node is a check has no emphasis at all.

## Connectors and labels

Connectors are thin ink lines with a small filled arrowhead, running from one
node's boundary to the next node's. Every connector ends in exactly one
arrowhead, pointing into the node it feeds.

Edge labels must never sit under the stroke, and the fix differs by direction:

- **Top-down.** The label rides the arrow, and the line is split into two
  segments with a gap around the text, so the stroke appears to pass behind it.
  This is what keeps a transparent PNG clean — an opaque patch behind the label
  would show as a rectangle against whatever the image is dropped onto.
- **Left-to-right.** Between-rank runs are too short to give up a gap, so the
  label sits just above an unbroken line instead.

On an ivory-background variant you may knock the line out with a
canvas-colored rounded rect behind the label. It reads slightly cleaner there,
and it is wrong on transparent output for the reason above.

## Layout

Top-down is the default; most flowcharts read best that way. Go horizontal only
for a short, wide flow or when asked.

Nodes share a center line, connect bottom-to-top, and hold a steady vertical
rhythm. A node grows horizontally to fit its longest line rather than clipping
it — an over-wide node looks fine, a truncated label does not.

Optional soft depth: a faint drop shadow on node rects. Keep it faint; the style
is mostly flat.

## Typography

Pretendard, with Korean-capable fallbacks, set on the root `<svg>` so every text
element inherits it. Titles and terminator labels run semibold; subtitles and
edge labels are lighter and a step down in size, in the muted inks.

For an exported PNG to actually render in Pretendard, the font must be visible
to the renderer through fontconfig. `scripts/render_png.py` installs whatever
sits in `assets/fonts/` before rasterizing, which is what makes the PNG match
the SVG. A missing font is never a blocker — the stack falls back one step and
you note it to the user.

## Checklist before export

- Titles and subtitles fit inside their nodes; nothing clips a rounded corner.
- Every connector carries exactly one arrowhead, landing on the right node.
- No stroke crosses label text.
- Step numbers are sequential and appear only on process and check nodes.
- Only the palette's colors appear.
