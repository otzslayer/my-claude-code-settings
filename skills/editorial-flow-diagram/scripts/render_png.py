#!/usr/bin/env python3
"""Rasterize an editorial flow diagram SVG to PNG.

Picks whichever SVG renderer is present (rsvg-convert, cairosvg, or
ImageMagick) and paints the background in that same pass, so no compositing
step and no Pillow are involved. Default background is transparent.

Usage:
    python3 render_png.py input.svg output.png [--background transparent|ivory|both]
                                               [--scale 3] [--ivory-hex #F0EEE6]

`build_diagram.py` imports `render()` and `install_bundled_fonts()` from here;
this module is the single place that knows how an SVG becomes a PNG.

Exit codes: 0 on success, non-zero on failure (message on stderr).
"""
from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

IVORY_DEFAULT = "#F0EEE6"
FONT_EXTS = frozenset({".ttf", ".otf", ".ttc"})
FALLBACK_SIZE = (760.0, 1000.0)


def install_bundled_fonts(skill_root: Path) -> list[str]:
    """Make fonts bundled in ``<skill_root>/assets/fonts`` visible to the renderer.

    Diagrams declare `font-family: Pretendard, ...`, but rsvg/ImageMagick resolve
    fonts through fontconfig by family name, so the file must exist on the
    system. Missing fonts are not an error: the diagram falls back to the next
    family in the stack. The fontconfig cache is refreshed only when a file was
    actually copied, which keeps repeat renders fast.

    Returns the names of the fonts now available (empty if none are bundled).
    """
    fonts_dir = skill_root / "assets" / "fonts"
    if not fonts_dir.is_dir():
        return []

    sources = [p for p in sorted(fonts_dir.iterdir())
               if p.is_file() and p.suffix.lower() in FONT_EXTS]
    if not sources:
        return []

    dest = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")) / "fonts"
    dest.mkdir(parents=True, exist_ok=True)

    available: list[str] = []
    copied = False
    for src in sources:
        target = dest / src.name
        try:
            if not target.exists() or target.stat().st_size != src.stat().st_size:
                shutil.copy2(src, target)
                copied = True
            available.append(src.name)
        except OSError as e:
            print(f"warning: could not install font {src.name}: {e}", file=sys.stderr)

    if copied and shutil.which("fc-cache"):
        subprocess.run(["fc-cache", "-f", str(dest)], check=False, capture_output=True)
    return available


def read_svg_size(svg_path: Path) -> tuple[float, float]:
    """Best-effort read of the SVG's nominal width/height, for scaling."""
    head = svg_path.read_text(encoding="utf-8", errors="ignore")[:2000]

    def attr(name: str) -> float | None:
        m = re.search(rf'{name}\s*=\s*"([0-9.]+)', head)
        return float(m.group(1)) if m else None

    w, h = attr("width"), attr("height")
    if w and h:
        return w, h

    m = re.search(r'viewBox\s*=\s*"([-0-9.]+)\s+([-0-9.]+)\s+([0-9.]+)\s+([0-9.]+)"', head)
    if m:
        return float(m.group(3)), float(m.group(4))
    return FALLBACK_SIZE


def render(svg_path: Path, out_path: Path, scale: float,
           background: str | None = None) -> None:
    """Render `svg_path` to `out_path` at `scale`, on `background` or transparent.

    Raises RuntimeError when no renderer is installed.
    """
    w, h = read_svg_size(svg_path)
    out_w, out_h = max(1, round(w * scale)), max(1, round(h * scale))
    out_path.parent.mkdir(parents=True, exist_ok=True)

    if shutil.which("rsvg-convert"):
        subprocess.run(
            ["rsvg-convert", "-w", str(out_w), "-h", str(out_h),
             "-b", background or "none", str(svg_path), "-o", str(out_path)],
            check=True,
        )
        return

    try:
        import cairosvg  # type: ignore[import-not-found]

        cairosvg.svg2png(url=str(svg_path), write_to=str(out_path),
                         output_width=out_w, output_height=out_h,
                         background_color=background)
        return
    except ImportError:
        pass

    magick = shutil.which("magick") or shutil.which("convert")
    if magick:
        cmd = [magick] if magick.endswith("convert") else [magick, "convert"]
        subprocess.run(
            cmd + ["-background", background or "none",
                   "-density", str(round(96 * scale)),
                   str(svg_path), str(out_path)],
            check=True,
        )
        return

    raise RuntimeError(
        "No SVG renderer found. Install one of: librsvg (brew install librsvg), "
        "cairosvg (pip install cairosvg), or ImageMagick."
    )


def main(argv: list[str] | None = None) -> int:
    p = argparse.ArgumentParser(description="Render an SVG flow diagram to PNG.")
    p.add_argument("input", type=Path, help="Input .svg path")
    p.add_argument("output", type=Path, help="Output .png path")
    p.add_argument("--background", choices=["transparent", "ivory", "both"],
                   default="transparent", help="PNG background (default: transparent)")
    p.add_argument("--scale", type=float, default=3.0,
                   help="Multiplier on the SVG's nominal size (default: 3)")
    p.add_argument("--ivory-hex", default=IVORY_DEFAULT,
                   help=f"Ivory background color (default: {IVORY_DEFAULT})")
    args = p.parse_args(argv)

    if not args.input.exists():
        print(f"error: input not found: {args.input}", file=sys.stderr)
        return 2

    skill_root = Path(__file__).resolve().parent.parent
    fonts = install_bundled_fonts(skill_root)
    if not fonts and (skill_root / "assets" / "fonts").is_dir():
        print("note: no font files in assets/fonts/ — the diagram will use a "
              "fallback face. Drop Pretendard-Regular/SemiBold there to match "
              "the SVG.", file=sys.stderr)

    made: list[Path] = []
    try:
        if args.background in ("transparent", "both"):
            render(args.input, args.output, args.scale, None)
            made.append(args.output)
        if args.background in ("ivory", "both"):
            ivory_out = (args.output.with_name(args.output.stem + "_ivory.png")
                         if args.background == "both" else args.output)
            render(args.input, ivory_out, args.scale, args.ivory_hex)
            made.append(ivory_out)
    except (RuntimeError, subprocess.CalledProcessError) as e:
        print(f"error: rendering failed: {e}", file=sys.stderr)
        return 1

    print("wrote: " + ", ".join(str(m) for m in made))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
