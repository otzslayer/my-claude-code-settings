#!/usr/bin/env python3
"""Build an editorial flow diagram (SVG + PNG) from a compact JSON spec.

Layout comes from Graphviz `dot` (branches, merges, back-edge loops, side
branches); every stroke is drawn here in the skill's own visual language, so
nothing of Graphviz's default look survives into the output.

Usage:
    python3 build_diagram.py spec.json [--name rag_flow] [--out DIR]
                             [--format png|svg|both]
                             [--background transparent|ivory|both]
                             [--scale 3] [--no-preview]

Writes the formats named by --format (default: png) into <out>/<name>.png
and/or <out>/<name>.svg, plus (unless --no-preview) <out>/<name>_preview.png —
a small ivory-backed image to eyeball before delivering. The SVG is always
built, because the PNG and the preview render from it; when --format leaves it
out it is built in a temporary directory and removed afterwards.

Spec format: see SKILL.md. Minimal shape:
    {"nodes": {"a": {"label": "Query", "role": "terminator"},
               "b": {"label": "Retrieve", "subtitle": "top-k"}},
     "edges": [["a", "b", "user input"]]}

Exit codes: 0 on success, non-zero on failure (message on stderr).
"""
from __future__ import annotations

import argparse
import json
import math
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from render_png import IVORY_DEFAULT, install_bundled_fonts, render  # noqa: E402

# --- design system: the single source of truth for every number and hex -------

INK = "#141413"
MUTED_INK = "#6E6B60"
LABEL_INK = "#55534B"
CLAY = "#C9755A"
CLAY_TINT = "#F4E4DC"
CLAY_TEXT = "#8A5A48"
NODE_FILL = "#FBFAF6"
ON_ACCENT = "#FBF9F4"

FONT_STACK = ("Pretendard,'Pretendard Variable','Apple SD Gothic Neo',"
              "'Noto Sans KR','Malgun Gothic','Helvetica Neue',Arial,sans-serif")

TITLE_SIZE = 17.0
SUBTITLE_SIZE = 12.5
EDGE_LABEL_SIZE = 12.5
BADGE_SIZE = 14.0
HEADER_SIZE = 26.0

NODE_H = 76.0            # process / check
TERM_H = 56.0            # terminator pill
NODE_MIN_W = 340.0
TERM_MIN_W = 180.0
TEXT_PAD = 56.0          # horizontal breathing room around the widest line
BADGE_R = 15.0
CANVAS_PAD = 28.0        # viewBox margin; also clears the left-hanging badge

RANKSEP = 0.62           # inches; labelled edges expand this on their own
NODESEP = 0.5

ROLES = ("terminator", "process", "check")


# --- text metrics -------------------------------------------------------------

def text_width(text: str, size: float) -> float:
    """Approximate rendered advance width in px, good enough for node sizing.

    Deliberately errs wide: an over-wide node looks fine, a clipped label does
    not. CJK/Hangul are full-width; Latin uses per-class averages.
    """
    total = 0.0
    for ch in text:
        o = ord(ch)
        if o > 0x1100:
            total += size * 1.0
        elif ch == " ":
            total += size * 0.28
        elif ch in "iljItf.,:;'|!()[]-":
            total += size * 0.32
        elif ch in "mwMW@":
            total += size * 0.88
        elif ch.isupper() or ch.isdigit():
            total += size * 0.63
        else:
            total += size * 0.55
    return total


# --- spec parsing -------------------------------------------------------------

class SpecError(ValueError):
    pass


class Node:
    def __init__(self, nid: str, raw: dict):
        self.id = nid
        self.label = str(raw.get("label", nid))
        self.subtitle = raw.get("subtitle") or ""
        self.role = raw.get("role", "process")
        if self.role not in ROLES:
            raise SpecError(f"node {nid!r}: role must be one of {ROLES}, got {self.role!r}")
        self.number: int | None = None
        self.w = 0.0
        self.h = 0.0
        self.cx = 0.0
        self.cy = 0.0

    @property
    def is_term(self) -> bool:
        return self.role == "terminator"

    def size(self) -> None:
        if self.is_term:
            self.h = TERM_H
            self.w = max(TERM_MIN_W, text_width(self.label, TITLE_SIZE) + TEXT_PAD)
        else:
            self.h = NODE_H
            widest = max(text_width(self.label, TITLE_SIZE),
                         text_width(self.subtitle, SUBTITLE_SIZE))
            self.w = max(NODE_MIN_W, widest + TEXT_PAD)


class Edge:
    def __init__(self, src: str, dst: str, label: str = ""):
        self.src = src
        self.dst = dst
        self.label = label
        self.points: list[tuple[float, float]] = []
        self.lp: tuple[float, float] | None = None


def parse_spec(spec: dict) -> tuple[dict[str, Node], list[Edge], dict]:
    raw_nodes = spec.get("nodes")
    if not raw_nodes:
        raise SpecError("spec needs a non-empty 'nodes'")

    nodes: dict[str, Node] = {}
    if isinstance(raw_nodes, dict):
        for nid, raw in raw_nodes.items():
            nodes[nid] = Node(nid, raw if isinstance(raw, dict) else {"label": raw})
    else:  # list of objects carrying their own id
        for raw in raw_nodes:
            nid = raw.get("id") or raw.get("label")
            if not nid:
                raise SpecError("every node in a list needs an 'id' or 'label'")
            nodes[str(nid)] = Node(str(nid), raw)

    edges: list[Edge] = []
    for raw in spec.get("edges", []):
        if isinstance(raw, (list, tuple)):
            src, dst = raw[0], raw[1]
            label = raw[2] if len(raw) > 2 else ""
        else:
            src = raw.get("from") or raw.get("src")
            dst = raw.get("to") or raw.get("dst")
            label = raw.get("label", "")
        if src not in nodes or dst not in nodes:
            raise SpecError(f"edge {src!r} -> {dst!r} names an undeclared node")
        edges.append(Edge(str(src), str(dst), str(label or "")))

    # Step badges number the process/check nodes in declaration order, which is
    # the reading order the caller chose. Terminators stay unnumbered.
    n = 0
    for node in nodes.values():
        node.size()
        if not node.is_term:
            n += 1
            node.number = n

    return nodes, edges, spec


# --- layout via graphviz ------------------------------------------------------

def _parse_spline(pos: str) -> tuple[list[tuple[float, float]], tuple[float, float] | None]:
    """Parse a graphviz edge `pos` into control points plus the arrow endpoint."""
    end: tuple[float, float] | None = None
    pts: list[tuple[float, float]] = []
    for tok in pos.replace("\\\n", " ").split():
        if tok.startswith("e,"):
            x, y = tok[2:].split(",")
            end = (float(x), float(y))
        elif tok.startswith("s,"):
            continue
        else:
            x, y = tok.split(",")
            pts.append((float(x), float(y)))
    return pts, end


def _flatten(ctrl: list[tuple[float, float]], step: float = 3.0) -> list[tuple[float, float]]:
    """Flatten a graphviz cubic B-spline chain (p0, then triples) to a polyline.

    Polylines make the label gap a slice of a list instead of a curve
    subdivision, and at this step size they are visually indistinguishable
    from the curve.
    """
    if len(ctrl) < 4:
        return list(ctrl)
    out: list[tuple[float, float]] = [ctrl[0]]
    for i in range(0, len(ctrl) - 3, 3):
        p0, p1, p2, p3 = ctrl[i:i + 4]
        span = (math.dist(p0, p1) + math.dist(p1, p2) + math.dist(p2, p3)) or 1.0
        n = max(4, int(span / step))
        for k in range(1, n + 1):
            t = k / n
            u = 1 - t
            x = (u ** 3 * p0[0] + 3 * u * u * t * p1[0]
                 + 3 * u * t * t * p2[0] + t ** 3 * p3[0])
            y = (u ** 3 * p0[1] + 3 * u * u * t * p1[1]
                 + 3 * u * t * t * p2[1] + t ** 3 * p3[1])
            out.append((x, y))
    return out


def layout(nodes: dict[str, Node], edges: list[Edge], direction: str) -> tuple[float, float]:
    """Run `dot`, then write positions back onto the nodes and edges (y flipped)."""
    lines = [
        "digraph G {",
        f"  rankdir={direction};",
        "  splines=spline;",
        f"  ranksep={RANKSEP}; nodesep={NODESEP};",
        "  node [shape=box, fixedsize=true, label=\"\"];",
        "  edge [fontsize=12, fontname=Helvetica];",
    ]
    for nid, nd in nodes.items():
        lines.append(f'  "{_dot_escape(nid)}" '
                     f'[width={nd.w / 72:.4f}, height={nd.h / 72:.4f}];')
    for e in edges:
        attr = f' [label="{_layout_label(e.label)}"]' if e.label else ""
        lines.append(f'  "{_dot_escape(e.src)}" -> "{_dot_escape(e.dst)}"{attr};')
    lines.append("}")
    src = "\n".join(lines)

    if not shutil.which("dot"):
        raise RuntimeError(
            "graphviz `dot` not found — install it (brew install graphviz) or "
            "hand-author the SVG following references/style_guide.md."
        )
    proc = subprocess.run(["dot", "-Tjson"], input=src, capture_output=True,
                          text=True, check=True)
    data = json.loads(proc.stdout)

    _, _, bw, bh = (float(v) for v in data["bb"].split(","))

    gvid_to_id: dict[int, str] = {}
    for obj in data.get("objects", []):
        nid = obj["name"]
        gvid_to_id[obj["_gvid"]] = nid
        x, y = (float(v) for v in obj["pos"].split(","))
        nodes[nid].cx = x
        nodes[nid].cy = bh - y  # graphviz is y-up, SVG is y-down

    by_pair: dict[tuple[str, str], list[Edge]] = {}
    for e in edges:
        by_pair.setdefault((e.src, e.dst), []).append(e)

    for ge in data.get("edges", []):
        key = (gvid_to_id[ge["tail"]], gvid_to_id[ge["head"]])
        bucket = by_pair.get(key)
        if not bucket:
            continue
        e = bucket.pop(0)
        ctrl, end = _parse_spline(ge["pos"])
        poly = _flatten(ctrl)
        if end:
            poly.append(end)
        e.points = [(x, bh - y) for x, y in poly]
        if ge.get("lp"):
            lx, ly = (float(v) for v in ge["lp"].split(","))
            e.lp = (lx, bh - ly)

    return bw, bh


DOT_LABEL_EM = 10.0   # width of one "M" at graphviz's Helvetica 12


def _layout_label(text: str) -> str:
    """A latin stand-in as wide as the real label will render.

    Graphviz only ever sizes the corridor it reserves between ranks — the text
    itself is drawn here — and its Helvetica metrics make Hangul about half its
    true width, which crowds a Korean label against the nodes on either side.
    Handing it a run of `M`s of the right width fixes the reservation without
    touching what the reader sees.
    """
    span = text_width(text, EDGE_LABEL_SIZE) + 16
    return "M" * max(1, round(span / DOT_LABEL_EM))


def _dot_escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


# --- drawing ------------------------------------------------------------------

def _esc(text: str) -> str:
    return (text.replace("&", "&amp;").replace("<", "&lt;")
            .replace(">", "&gt;").replace('"', "&quot;"))


def _cumulative(points: list[tuple[float, float]]) -> list[float]:
    acc = [0.0]
    for a, b in zip(points, points[1:]):
        acc.append(acc[-1] + math.dist(a, b))
    return acc


def _point_at(points: list[tuple[float, float]], acc: list[float], s: float) -> tuple[float, float]:
    s = min(max(s, 0.0), acc[-1])
    for i in range(1, len(acc)):
        if acc[i] >= s:
            t = (s - acc[i - 1]) / max(acc[i] - acc[i - 1], 1e-9)
            (x0, y0), (x1, y1) = points[i - 1], points[i]
            return (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
    return points[-1]


def _slice(points: list[tuple[float, float]], acc: list[float],
           s0: float, s1: float) -> list[tuple[float, float]]:
    out = [_point_at(points, acc, s0)]
    out += [p for p, a in zip(points, acc) if s0 < a < s1]
    out.append(_point_at(points, acc, s1))
    return out


def _path_d(points: list[tuple[float, float]]) -> str:
    head = f"M{points[0][0]:.2f},{points[0][1]:.2f}"
    return head + "".join(f"L{x:.2f},{y:.2f}" for x, y in points[1:])


def _label(x: float, y: float, text: str, boxes: list[tuple[float, float, float, float]]) -> str:
    """Emit a centered edge label and record the box it occupies.

    The boxes widen the viewBox later: graphviz sizes labels with its own font
    metrics, which run narrow for Hangul, so its bounding box alone would clip
    them.
    """
    half_w = text_width(text, EDGE_LABEL_SIZE) / 2
    boxes.append((x - half_w, y - EDGE_LABEL_SIZE, x + half_w, y + EDGE_LABEL_SIZE * 0.4))
    return (f'<text x="{x:.2f}" y="{y:.2f}" text-anchor="middle" '
            f'font-size="{EDGE_LABEL_SIZE}" fill="{LABEL_INK}">{_esc(text)}</text>')


def draw_edge(e: Edge, direction: str,
              boxes: list[tuple[float, float, float, float]]) -> list[str]:
    """Draw one connector so its label never sits on top of the line.

    A top-down connector carries its label riding the arrow, so the line is
    split around it. A left-to-right one is short between ranks and would be
    eaten by that gap, so the label rides above the arrow instead and the line
    stays whole — the placement graphviz already reserved room for.
    """
    pts = e.points
    if len(pts) < 2:
        return []
    out: list[str] = []
    acc = _cumulative(pts)

    if not e.label:
        out.append(f'<path d="{_path_d(pts)}" marker-end="url(#arrow)"/>')
        return out

    if e.src == e.dst:
        # A self-loop doubles back, so one gap cannot clear both passes of the
        # curve. Park the label outside the loop instead.
        out.append(f'<path d="{_path_d(pts)}" marker-end="url(#arrow)"/>')
        far = max(pts, key=lambda p: p[0])
        offset = text_width(e.label, EDGE_LABEL_SIZE) / 2 + 10
        out.append(_label(far[0] + offset, far[1] + EDGE_LABEL_SIZE * 0.36,
                          e.label, boxes))
        return out

    if direction == "LR":
        out.append(f'<path d="{_path_d(pts)}" marker-end="url(#arrow)"/>')
        anchor = e.lp or _point_at(pts, acc, acc[-1] / 2)
        # Take the horizontal placement graphviz chose, but lift the text clear
        # of the line rather than letting the stroke underline it.
        near = min(pts, key=lambda p: abs(p[0] - anchor[0]))
        out.append(_label(anchor[0], near[1] - EDGE_LABEL_SIZE * 0.55, e.label, boxes))
        return out

    # Snap the label onto the line: dot parks it beside the spline (and has
    # already reserved room there), so the nearest point on the curve keeps that
    # collision-free placement while satisfying the labels-ride-the-arrow rule.
    target = e.lp or _point_at(pts, acc, acc[-1] / 2)
    best_i = min(range(len(pts)), key=lambda i: math.dist(pts[i], target))
    s_mid = acc[best_i]

    half_w = text_width(e.label, EDGE_LABEL_SIZE) / 2 + 7
    half_h = EDGE_LABEL_SIZE / 2 + 5

    def gap_at(index: int) -> float:
        """How far the label box reaches along the line's own direction.

        A vertical connector has to clear the text's height, a horizontal one
        its width, and a diagonal something between the two.
        """
        j, k = min(index + 1, len(pts) - 1), max(index - 1, 0)
        tx, ty = pts[j][0] - pts[k][0], pts[j][1] - pts[k][1]
        norm = math.hypot(tx, ty) or 1.0
        tx, ty = tx / norm, ty / norm
        reach = [abs(half_w / tx)] if abs(tx) > 1e-6 else []
        if abs(ty) > 1e-6:
            reach.append(abs(half_h / ty))
        return min(reach) if reach else half_h

    # Keep the label clear of both endpoints, or a short connector ends up with
    # its arrowhead sitting on the text.
    gap = gap_at(best_i)
    margin = gap + 10
    if acc[-1] > margin * 2:
        s_mid = min(max(s_mid, margin), acc[-1] - margin)
        best_i = min(range(len(pts)), key=lambda i: abs(acc[i] - s_mid))
        gap = gap_at(best_i)
    else:
        s_mid = acc[-1] / 2
    lx, ly = _point_at(pts, acc, s_mid)

    if s_mid - gap > 1.0:
        out.append(f'<path d="{_path_d(_slice(pts, acc, 0, s_mid - gap))}"/>')
    tail = _slice(pts, acc, min(s_mid + gap, acc[-1] - 0.5), acc[-1])
    out.append(f'<path d="{_path_d(tail)}" marker-end="url(#arrow)"/>')
    out.append(_label(lx, ly + EDGE_LABEL_SIZE * 0.36, e.label, boxes))
    return out


def draw_node(n: Node, direction: str) -> list[str]:
    x = n.cx - n.w / 2
    y = n.cy - n.h / 2
    out: list[str] = []

    if n.is_term:
        out.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{n.w:.2f}" '
                   f'height="{n.h:.2f}" rx="{n.h / 2:.2f}" fill="{CLAY}" '
                   f'filter="url(#soft)"/>')
        out.append(f'<text x="{n.cx:.2f}" y="{n.cy + 6:.2f}" text-anchor="middle" '
                   f'font-size="{TITLE_SIZE}" font-weight="600" '
                   f'fill="{ON_ACCENT}">{_esc(n.label)}</text>')
        return out

    check = n.role == "check"
    fill = CLAY_TINT if check else NODE_FILL
    stroke = CLAY if check else INK
    sw = 1.8 if check else 1.5
    out.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{n.w:.2f}" height="{n.h:.2f}" '
               f'rx="14" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" '
               f'filter="url(#soft)"/>')

    if n.subtitle:
        out.append(f'<text x="{n.cx:.2f}" y="{n.cy - 4:.2f}" text-anchor="middle" '
                   f'font-size="{TITLE_SIZE}" font-weight="600" '
                   f'fill="{INK}">{_esc(n.label)}</text>')
        out.append(f'<text x="{n.cx:.2f}" y="{n.cy + 18:.2f}" text-anchor="middle" '
                   f'font-size="{SUBTITLE_SIZE}" '
                   f'fill="{CLAY_TEXT if check else MUTED_INK}">'
                   f'{_esc(n.subtitle)}</text>')
    else:
        out.append(f'<text x="{n.cx:.2f}" y="{n.cy + 6:.2f}" text-anchor="middle" '
                   f'font-size="{TITLE_SIZE}" font-weight="600" '
                   f'fill="{INK}">{_esc(n.label)}</text>')

    if n.number is not None:
        # The badge sits on the border the flow does not arrive through: the
        # left edge in a top-down flow, the top edge in a left-to-right one.
        bx, by = (x, n.cy) if direction == "TB" else (x + BADGE_R + 11, y)
        out.append(f'<circle cx="{bx:.2f}" cy="{by:.2f}" r="{BADGE_R}" fill="{CLAY}"/>')
        out.append(f'<text x="{bx:.2f}" y="{by + 5:.2f}" text-anchor="middle" '
                   f'font-size="{BADGE_SIZE}" font-weight="600" '
                   f'fill="{ON_ACCENT}">{n.number}</text>')
    return out


def build_svg(nodes: dict[str, Node], edges: list[Edge], bw: float, bh: float,
              spec: dict, direction: str) -> str:
    body: list[str] = []
    body.append(f'<g stroke="{INK}" stroke-width="1.6" fill="none" '
                f'stroke-linejoin="round">')
    boxes: list[tuple[float, float, float, float]] = []
    label_texts: list[str] = []
    for e in edges:
        for frag in draw_edge(e, direction, boxes):
            (label_texts if frag.startswith("<text") else body).append(frag)
    body.append("</g>")
    body.extend(label_texts)
    for n in nodes.values():
        body.extend(draw_node(n, direction))

    hang = BADGE_R if direction == "TB" else 0.0  # left-hanging step badges
    left = min([-hang] + [b[0] for b in boxes]) - CANVAS_PAD
    top = min([0.0] + [b[1] for b in boxes]) - CANVAS_PAD
    right = max([bw] + [b[2] for b in boxes]) + CANVAS_PAD
    bottom = max([bh] + [b[3] for b in boxes]) + CANVAS_PAD
    width = right - left
    height = bottom - top

    header: list[str] = []
    title = spec.get("title")
    subtitle = spec.get("subtitle")
    if title:
        block = HEADER_SIZE + (22 if subtitle else 0) + 26
        top -= block
        height += block
        header.append(f'<text x="{left + CANVAS_PAD:.2f}" y="{top + HEADER_SIZE:.2f}" '
                      f'font-size="{HEADER_SIZE}" font-weight="600" '
                      f'fill="{INK}">{_esc(title)}</text>')
        if subtitle:
            header.append(f'<text x="{left + CANVAS_PAD:.2f}" '
                          f'y="{top + HEADER_SIZE + 22:.2f}" font-size="14" '
                          f'fill="{MUTED_INK}">{_esc(subtitle)}</text>')

    legend: list[str] = []
    if spec.get("legend", True) and any(n.role == "check" for n in nodes.values()):
        ly = bottom - 4
        height += 34
        lx = left + CANVAS_PAD
        check_label = spec.get("check_meaning", "Check step")
        legend.append(f'<g font-size="12" fill="{MUTED_INK}">')
        legend.append(f'<rect x="{lx:.2f}" y="{ly:.2f}" width="16" height="16" rx="4" '
                      f'fill="{CLAY_TINT}" stroke="{CLAY}" stroke-width="1.6"/>')
        legend.append(f'<text x="{lx + 24:.2f}" y="{ly + 12:.2f}">{_esc(check_label)}</text>')
        lx2 = lx + 34 + text_width(check_label, 12) + 30
        legend.append(f'<rect x="{lx2:.2f}" y="{ly:.2f}" width="16" height="16" rx="4" '
                      f'fill="{NODE_FILL}" stroke="{INK}" stroke-width="1.4"/>')
        legend.append(f'<text x="{lx2 + 24:.2f}" y="{ly + 12:.2f}">Processing step</text>')
        legend.append("</g>")

    return "\n".join([
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.0f}" '
        f'height="{height:.0f}" viewBox="{left:.2f} {top:.2f} {width:.2f} '
        f'{height:.2f}" font-family="{FONT_STACK}">',
        "  <defs>",
        '    <marker id="arrow" viewBox="0 0 10 10" refX="8.5" refY="5" '
        'markerWidth="7" markerHeight="7" orient="auto-start-reverse">',
        f'      <path d="M0,0 L10,5 L0,10 z" fill="{INK}"/>',
        "    </marker>",
        '    <filter id="soft" x="-20%" y="-20%" width="140%" height="140%">',
        f'      <feDropShadow dx="0" dy="2" stdDeviation="3" flood-color="{INK}" '
        'flood-opacity="0.10"/>',
        "    </filter>",
        "  </defs>",
        *("  " + line for line in header + body + legend),
        "</svg>",
    ]) + "\n"


# --- entry point --------------------------------------------------------------

DEFAULT_OUT = Path("~/Pictures/Diagrams")


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Build an editorial flow diagram.")
    p.add_argument("spec", type=Path, help="Path to the JSON spec ('-' for stdin)")
    p.add_argument("--name", help="Output basename (default: the spec's filename)")
    p.add_argument("--out", type=Path, default=DEFAULT_OUT,
                   help=f"Output directory (default: {DEFAULT_OUT})")
    p.add_argument("--format", choices=["png", "svg", "both"], default="png",
                   help="Which outputs to deliver (default: png). The SVG is "
                        "always built internally; with --format png it lives "
                        "in a temporary directory and is removed after render")
    p.add_argument("--background", choices=["transparent", "ivory", "both"],
                   default="transparent",
                   help="PNG background (default: transparent); ignored with "
                        "--format svg, which renders no PNG")
    p.add_argument("--scale", type=float, default=3.0,
                   help="PNG resolution multiplier (default: 3)")
    p.add_argument("--no-preview", action="store_true",
                   help="Skip the small ivory preview image")
    args = p.parse_args(argv)

    text = sys.stdin.read() if str(args.spec) == "-" else args.spec.read_text(encoding="utf-8")
    try:
        spec = json.loads(text)
        nodes, edges, spec = parse_spec(spec)
    except (json.JSONDecodeError, SpecError) as e:
        print(f"error: bad spec: {e}", file=sys.stderr)
        return 2

    direction = str(spec.get("direction", "TB")).upper()
    if direction not in ("TB", "LR"):
        print(f"error: direction must be TB or LR, got {direction!r}", file=sys.stderr)
        return 2

    try:
        bw, bh = layout(nodes, edges, direction)
    except (RuntimeError, subprocess.CalledProcessError) as e:
        print(f"error: layout failed: {e}", file=sys.stderr)
        return 1

    name = args.name or re.sub(r"\.json$", "", args.spec.name) or "diagram"
    out_dir = args.out.expanduser()
    out_dir.mkdir(parents=True, exist_ok=True)
    svg_text = build_svg(nodes, edges, bw, bh, spec, direction)
    keep_svg = args.format in ("svg", "both")

    install_bundled_fonts(Path(__file__).resolve().parent.parent)

    with tempfile.TemporaryDirectory() as tmp:
        svg_path = (out_dir if keep_svg else Path(tmp)) / f"{name}.svg"
        svg_path.write_text(svg_text, encoding="utf-8")

        made = [svg_path] if keep_svg else []
        try:
            if args.format in ("png", "both"):
                png = out_dir / f"{name}.png"
                if args.background in ("transparent", "both"):
                    render(svg_path, png, args.scale, None)
                    made.append(png)
                if args.background in ("ivory", "both"):
                    ivory = out_dir / (f"{name}_ivory.png"
                                       if args.background == "both"
                                       else f"{name}.png")
                    render(svg_path, ivory, args.scale, IVORY_DEFAULT)
                    made.append(ivory)
            if not args.no_preview:
                preview = out_dir / f"{name}_preview.png"
                render(svg_path, preview, 900 / max(bw, 1.0), IVORY_DEFAULT)
                made.append(preview)
        except Exception as e:  # noqa: BLE001 - one clean message beats a traceback
            print(f"error: rendering failed: {e}", file=sys.stderr)
            return 1

    print("wrote: " + ", ".join(str(m) for m in made))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
