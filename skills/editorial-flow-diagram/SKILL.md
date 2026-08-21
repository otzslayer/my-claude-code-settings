---
name: editorial-flow-diagram
description: >-
  Redraw a flowchart, pipeline, or process diagram in a clean editorial
  engineering-blog style (warm ivory canvas, charcoal-outlined rounded nodes,
  clay accent, thin labelled arrows) and deliver a high-resolution PNG by
  default, or an editable SVG, or both, as the user asks.
  Handles branches, merges, side paths, and retry loops.
  Use whenever the user wants a diagram redrawn, restyled, or cleaned up, or
  asks for a flow / pipeline / architecture diagram in a minimalist, editorial,
  or engineering-blog look. Works from any of three inputs: an existing diagram
  file or URL (a mermaid-rendered .svg, a .mmd source, or any SVG flowchart), a
  prose description of the flow ("A → B → C, then check X…"), or a screenshot of
  a flowchart. Trigger even when the user only names the two outputs (SVG + PNG)
  or says "make this look like a clean engineering-blog diagram".
---

# Editorial Flow Diagram

Turn any flow into a polished diagram in the visual language of modern
engineering blog posts. What gets delivered is up to `--format`: a rasterized
**PNG** (transparent by default, ready to drop into slides and docs) is the
default, a vector **SVG** (source of truth, easy to tweak) the alternative, and
`both` hands over the pair. Honour whatever the user asked for; when they say
nothing about the format, take the PNG default and move on rather than asking.

You describe the flow as a JSON spec; `scripts/build_diagram.py` does the rest.
Graphviz computes the layout, so branches, merges, side paths, and back-edge
loops all place themselves — but every stroke is drawn in the skill's own
palette and geometry, and nothing of Graphviz's default look reaches the output.
Hand-writing SVG coordinates is the slow, error-prone path; take it only for the
exception cases named at the end.

## Workflow

### 1. Extract the nodes and edges

You need a list of **nodes** (label + optional one-line role) and **edges**
(from → to + optional label). How you get there depends on the input:

- **Existing SVG / mermaid file or URL.** In a mermaid-rendered SVG the node
  text lives in `g.node` elements and edge text in `.edgeLabel` — parse those.
  When a URL won't fetch as text (many raw SVGs come back empty), open it in the
  browser and read the live DOM:
  `[...document.querySelectorAll('g.node')].map(n => n.textContent.trim())`, and
  the same for `.edgeLabel`. For a `.mmd` source, read the arrows directly.
- **Prose description.** Parse the user's text into the node/edge list. Ask a
  clarifying question only when the ordering or branching is genuinely
  ambiguous; otherwise infer sensibly and proceed.
- **Screenshot.** Read the image and transcribe the boxes and arrows. Say that
  this transcription is best-effort and invite corrections.

Carry the source's own labels over verbatim (an edge label like
`retrieved docs + query` stays exactly that). Add a subtitle to a node only when
it genuinely aids clarity, and keep it factual — never invent behavior the
source doesn't show.

### 2. Give every node a role

- **terminator** — the flow's start and end. A clay pill, unnumbered.
- **check** — a validation, decision, gate, guard, or approval. Clay-tinted,
  because these are the steps a reader most wants to notice. Used sparingly:
  when everything is a check, nothing is.
- **process** — everything else. The default.

### 3. Write the spec

```json
{
  "title": "RAG pipeline",
  "subtitle": "retrieval through grounded answer",
  "direction": "TB",
  "nodes": {
    "q":   {"label": "Query", "role": "terminator"},
    "r":   {"label": "Retrieve", "subtitle": "top-k from vector store"},
    "c":   {"label": "Relevance check", "role": "check"},
    "w":   {"label": "Web search", "subtitle": "fallback source"},
    "g":   {"label": "Generate"},
    "end": {"label": "Answer", "role": "terminator"}
  },
  "edges": [
    ["q", "r", "user input"],
    ["r", "c", "retrieved docs + query"],
    ["c", "g", "relevant"],
    ["c", "w", "not relevant"],
    ["w", "g", "web docs"],
    ["g", "end", "grounded"],
    ["g", "c", "retry"]
  ]
}
```

- `role` defaults to `process`. A node's `subtitle` and the header's `title` /
  `subtitle` are all optional; omit the header for a bare diagram.
- `direction` is `TB` (top-down, the default and right for most flows) or `LR`.
  Reach for `LR` only when the user asks or the flow is short and wide.
- An edge is `[from, to, label]`, and the label may be dropped: `["a", "b"]`.
  The object form `{"from": "a", "to": "b", "label": "…"}` also works.
- Branches are two edges out of one node, merges two edges into one, and loops
  an edge pointing back at an earlier node. Write them and the layout follows.
- Step badges number the process and check nodes **in declaration order**, so
  declare nodes in the order you want a reader to walk them.
- A legend appears automatically when the diagram has check nodes. Name what a
  check means with `"check_meaning": "Reliability check"`, or drop it with
  `"legend": false`.

Write the spec to the scratchpad, not to the output folder.

### 4. Build

```bash
python3 scripts/build_diagram.py <spec.json> --name <basename> [--format png|svg|both]
```

This writes the requested outputs plus `<basename>_preview.png` into
`~/Pictures/Diagrams`, in about a second. Useful flags:

- `--format png|svg|both` — what to deliver; `png` is the default. The SVG is
  always built internally, because the PNG and the preview render from it, but
  under `--format png` it is built in a temporary directory and removed, so
  nothing but the PNG and the preview lands in the output folder.
- `--out DIR` — somewhere other than `~/Pictures/Diagrams`.
- `--background ivory` or `both` — an ivory (`#F0EEE6`) canvas instead of, or
  alongside, the transparent default. It affects the PNG only, so it does
  nothing under `--format svg`.
- `--scale N` — PNG resolution multiplier; the default of 3 gives a crisp
  ~2–3k-px-wide image.

### 5. Read the preview, then deliver

Open `<basename>_preview.png` and confirm all four:

- no text is clipped by its node or the canvas edge,
- no two nodes overlap,
- every arrow ends on the node its label implies,
- step numbers run in the reading order you intended.

The preview is built for this check whatever `--format` says; it is a working
file, not part of the delivery.

Fix the spec and rebuild if any fails — rebuilding costs a second. Then hand the
user the file or files their `--format` produced, say where they landed, and
mention that the other format, an ivory background, or a different scale is one
flag away. Call the SVG editable only when you actually delivered one.

## When to hand-author the SVG instead

The generator covers directed flows. For something outside that — swimlanes,
nested containers, free-form architecture drawings, or a one-off tweak to an
already-built SVG — edit the output directly or start from
`assets/template.svg`. Build with `--format svg` or `both` first, since the
default keeps no SVG to edit. `references/style_guide.md` carries the design rules you
need to keep a hand-drawn diagram in the same set as a generated one.

## Files

- `scripts/build_diagram.py` — spec → SVG → PNG. Owns the palette, geometry, and
  layout; change a color or a size here and everywhere follows.
- `scripts/render_png.py` — SVG → PNG on its own, for re-rendering an SVG you
  hand-edited. Also installs the bundled fonts.
- `references/style_guide.md` — design rules for hand-authoring.
- `assets/template.svg` — a skeleton with one of each node type.
- `assets/fonts/` — Pretendard, installed automatically at render time.
