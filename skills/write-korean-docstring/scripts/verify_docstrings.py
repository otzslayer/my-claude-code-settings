"""docstring만 바꾼 diff를 기계적으로 검증한다.

사용법:
    python3 verify_docstrings.py <패키지 디렉터리> [--base HEAD] [--width 80]
        [--dump <docstring 모음 .md 경로>]

점검 항목:
- CODE CHANGED: docstring을 지운 AST가 base와 다름. 코드가 바뀌었다는 뜻이다
- WIDE: base에 없던 줄이 한글 폭 기준 --width를 넘음
- MULTISUM: 첫 줄 요약이 두 줄 이상임
- COMPILE: "::" 뒤 코드 블록이 구문 오류임 (await를 허용하려고 async 함수로 감쌈)
- ENDING: "~다."로 끝나지만 "~니다."가 아닌 문장 (한다체 의심)
- GAEJO: 줄이 "~음.", "~함."처럼 개조식으로 끝남 (명사 끝 목록 항목은 사람이 판정)
- POINTER: docs/, ADR, "N장" 같은 바깥 참조

--dump를 주면 모든 docstring을 한 파일로 모은다. write-korean-doc의 check.py를
이 파일에 돌리고 통독할 때 쓴다. 문제가 하나라도 있으면 종료 코드 1이다.
"""

import argparse
import ast
import re
import subprocess
import sys
import textwrap
import unicodedata
from pathlib import Path

_DOC_NODES = (ast.Module, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)


def _width(s: str) -> int:
    return sum(2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)


def _strip_docstrings(src: str) -> str:
    tree = ast.parse(src)
    for node in ast.walk(tree):
        if (
            isinstance(node, _DOC_NODES)
            and node.body
            and isinstance(node.body[0], ast.Expr)
            and isinstance(node.body[0].value, ast.Constant)
            and isinstance(node.body[0].value.value, str)
        ):
            node.body = node.body[1:] or [ast.Pass()]
    return ast.dump(tree)


def _code_blocks(doc: str) -> list[str]:
    lines = doc.split("\n")
    blocks: list[str] = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.rstrip().endswith("::"):
            base = len(line) - len(line.lstrip())
            j = i + 1
            block: list[str] = []
            while j < len(lines) and (
                not lines[j].strip()
                or len(lines[j]) - len(lines[j].lstrip()) > base
            ):
                block.append(lines[j])
                j += 1
            blocks.append(textwrap.dedent("\n".join(block)).strip("\n"))
            i = j
        else:
            i += 1
    return blocks


def _prose(doc: str) -> str:
    out: list[str] = []
    skip_base: int | None = None
    for line in doc.split("\n"):
        lead = len(line) - len(line.lstrip())
        if skip_base is not None:
            if not line.strip() or lead > skip_base:
                continue
            skip_base = None
        out.append(line)
        if line.rstrip().endswith("::"):
            skip_base = lead
    return "\n".join(out)


_UNIT_START = re.compile(r"^(- |\d+\. |[\w*]+: |[A-Z][a-z]+:$)")


def _units(prose: str) -> list[str]:
    """줄 바꿈으로 끊긴 문단과 목록 항목을 이어 붙여 끝을 볼 수 있게 한다."""
    units: list[str] = []
    cur: list[str] = []
    for line in prose.split("\n"):
        text = line.strip()
        if not text or _UNIT_START.match(text):
            if cur:
                units.append(" ".join(cur))
            cur = [text] if text else []
        else:
            cur.append(text)
    if cur:
        units.append(" ".join(cur))
    return units


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package", type=Path)
    parser.add_argument("--base", default="HEAD")
    parser.add_argument("--width", type=int, default=80)
    parser.add_argument("--dump", type=Path)
    args = parser.parse_args()

    root = subprocess.run(
        ["git", "rev-parse", "--show-toplevel"],
        capture_output=True,
        text=True,
        check=True,
        cwd=args.package,
    ).stdout.strip()
    problems: list[str] = []
    dump: list[str] = []
    for path in sorted(args.package.rglob("*.py")):
        rel = path.resolve().relative_to(root)
        new = path.read_text(encoding="utf-8")
        shown = subprocess.run(
            ["git", "show", f"{args.base}:{rel}"],
            capture_output=True,
            text=True,
            cwd=root,
        )
        old = shown.stdout if shown.returncode == 0 else ""
        if old and _strip_docstrings(old) != _strip_docstrings(new):
            problems.append(f"CODE CHANGED {rel}")
        old_wide = {ln for ln in old.splitlines() if _width(ln) > args.width}
        for no, ln in enumerate(new.splitlines(), 1):
            if _width(ln) > args.width and ln not in old_wide:
                problems.append(f"WIDE {rel}:{no} ({_width(ln)}칸)")
        for node in ast.walk(ast.parse(new)):
            if not isinstance(node, _DOC_NODES):
                continue
            doc = ast.get_docstring(node)
            if not doc:
                continue
            name = getattr(node, "name", "<module>")
            where = f"{rel}:{name}"
            dump.append(f"## {where}\n\n{doc}\n")
            if "\n" in doc.split("\n\n")[0]:
                problems.append(f"MULTISUM {where}")
            for code in _code_blocks(doc):
                body = textwrap.indent(code, "    ")
                try:
                    compile(f"async def _():\n{body}\n", where, "exec")
                except SyntaxError as exc:
                    problems.append(f"COMPILE {where}: {exc.msg}")
            prose = _prose(doc)
            for word in re.findall(r"[가-힣]+다\.", prose):
                if not word.endswith("니다."):
                    problems.append(f"ENDING {where}: {word}")
            for unit in _units(prose):
                if re.search(r"[가-힣](음|함|됨|임)\.?$", unit):
                    problems.append(f"GAEJO {where}: {unit[-40:]}")
            for hit in re.findall(r"docs/\S+|ADR\s*\d*|\d+장", prose):
                problems.append(f"POINTER {where}: {hit}")
    if args.dump:
        args.dump.write_text("\n".join(dump), encoding="utf-8")
    for p in problems:
        print(p)
    print(f"문제 {len(problems)}건, docstring {len(dump)}개")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
