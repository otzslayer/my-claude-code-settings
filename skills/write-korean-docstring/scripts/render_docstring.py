"""한국어 docstring을 한글 폭 기준으로 줄 바꿈해 소스에 넣는 보조 모듈.

편집 스크립트에서 불러 쓴다.

    import sys
    sys.path.insert(0, "<이 스크립트가 있는 디렉터리>")
    from render_docstring import render as R, apply

    apply("pkg/_mod.py", [
        ('def f(x: int) -> int:\\n', 'def f(x: int) -> int:\\n'
         + R(DOC, "    ") + "\\n"),
    ])

render()의 입력 규칙:
- 문단은 줄 바꿈 없이 한 줄로 쓴다. 문단 사이는 빈 줄 하나다.
- 목록 항목("- ", "1. ")과 섹션 항목("name: ")은 한 줄로 쓰면 걸린 들여쓰기로
  줄을 바꾼다.
- "::"로 끝나는 줄 뒤에 그 줄보다 깊게 들여쓴 줄은 코드 블록으로 보고 그대로
  둔다.
- 첫 줄은 여는 따옴표와 같은 줄에 붙고 한 줄 docstring이면 닫는 따옴표도 붙는다.
"""

import re
import unicodedata
from pathlib import Path

SECTIONS = {
    "Args:",
    "Attributes:",
    "Raises:",
    "Returns:",
    "Yields:",
    "Example:",
    "Examples:",
    "Note:",
}
_ITEM_SECTIONS = {"Args:", "Attributes:", "Raises:"}


def width(s: str) -> int:
    """한글과 전각 문자를 두 칸으로 센 표시 폭."""
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


def _wrap(text: str, first: str, rest: str, limit: int) -> list[str]:
    lines: list[str] = []
    cur = first
    started = False
    for word in text.split(" "):
        cand = cur + (" " if started else "") + word
        if started and width(cand) > limit:
            lines.append(cur)
            cur = rest + word
        else:
            cur = cand
        started = True
    lines.append(cur)
    return lines


def render(doc: str, indent: str, limit: int = 80) -> str:
    """docstring 본문을 따옴표까지 포함한 소스 문자열로 바꾼다.

    indent는 따옴표 앞의 들여쓰기, limit은 줄 폭 상한이다.
    """
    src = doc.strip("\n").split("\n")
    out: list[str] = []
    section: str | None = None
    code_base: int | None = None
    for i, raw in enumerate(src):
        stripped = raw.lstrip(" ")
        lead = len(raw) - len(stripped)
        if code_base is not None:
            if stripped == "" or lead > code_base:
                out.append((indent + raw).rstrip())
                continue
            code_base = None
        if stripped == "":
            out.append("")
            continue
        if stripped in SECTIONS:
            section = stripped
            out.append(indent + raw)
            continue
        pre = indent + " " * lead
        hang = 0
        if stripped.startswith("- "):
            hang = 2
        elif re.match(r"^\d+\. ", stripped):
            hang = stripped.index(" ") + 1
        elif (
            section in _ITEM_SECTIONS
            and lead > 0
            and re.match(r"^[\w*]+: ", stripped)
        ):
            hang = 4
        first = indent + '"""' if i == 0 else pre
        out.extend(_wrap(stripped, first, pre + " " * hang, limit))
        if stripped.endswith("::"):
            code_base = lead
    if len(out) == 1:
        return out[0] + '"""'
    out.append(indent + '"""')
    return "\n".join(out)


def apply(path: str, edits: list[tuple[str, str]]) -> None:
    """path에서 old를 new로 바꾼다. old가 정확히 한 번 나오지 않으면 멈춘다.

    모든 치환이 성공해야 파일을 쓴다. 그래서 중간에 멈추면 그 파일은 그대로다.
    """
    p = Path(path)
    s = p.read_text(encoding="utf-8")
    for old, new in edits:
        count = s.count(old)
        if count != 1:
            raise SystemExit(f"{path}: 대상이 {count}번 나옴: {old[:60]!r}")
        s = s.replace(old, new)
    p.write_text(s, encoding="utf-8")
