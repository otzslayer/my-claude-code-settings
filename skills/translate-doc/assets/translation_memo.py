#!/usr/bin/env python3
"""번역 메모장을 조회하고 확정된 번역 결정을 덧붙인다.

메모장(`translation-memo.jsonl`)은 한 줄에 한 결정이며 `term`, `ko`, `context`,
`doc`, `date` 다섯 필드를 담는다. 같은 `term`이 여러 줄인 것이 곧 다의어다.
옛 글로서리(`glossary.json`)는 외부 저장소 소유라 읽기 전용 폴백으로만 쓰이고,
맥락이 없으므로 신뢰도 낮은 후보로 구분해 내보낸다.

조회 결과는 강제가 아니라 후보다. 문서의 용법과 맞는지는 모델이 판정한다.

사용법:
    python3 translation_memo.py lookup <input_file>
    python3 translation_memo.py lookup --term alignment --term ReAct
    python3 translation_memo.py record --doc <doc> '[{"term":..,"ko":..,"context":..}]'
"""

from __future__ import annotations

import argparse
import datetime as dt
import json
import re
import sys
from collections.abc import Callable
from pathlib import Path

DEFAULT_MEMO = Path(__file__).with_name("translation-memo.jsonl")
DEFAULT_GLOSSARY = Path(__file__).with_name("glossary.json")

Entry = dict[str, str]

# 마크다운 줄머리 마커. 헤딩과 불릿 첫머리도 문장 첫머리로 친다.
LINE_LEAD = re.compile(r"(?:[#>*+-]|\d+[.)])\s*$")


def boundary_pattern(term: str) -> re.Pattern[str]:
    """단어 경계 위에서만, 대소문자를 구분해 매칭한다.

    영어 복수형 접미사(`-s`/`-es`)는 허용한다. 그것까지 막으면 `subagents`가
    `subagent`에 걸리지 않아 실제 용어를 놓친다. `agentic`은 여전히 배제된다.

    표기가 비영숫자로 시작하거나 끝나면 그쪽 경계는 붙이지 않는다.
    `(LLM)` 같은 괄호 표기가 통째로 탈락하는 것을 막는다.
    """
    prefix = r"(?<![A-Za-z0-9])" if term[:1].isalnum() else ""
    suffix = r"(?:e?s)?(?![A-Za-z0-9])" if term[-1:].isalnum() else ""
    return re.compile(prefix + re.escape(term) + suffix)


def is_sentence_start(text: str, pos: int) -> bool:
    """`pos`가 문장 첫머리인가. 마크다운 줄머리 마커는 걷어내고 본다."""
    before = text[:pos].rstrip(" \t")
    while (marker := LINE_LEAD.search(before)) is not None:
        before = before[: marker.start()].rstrip(" \t")
    return not before or before[-1] in ".!?\n"


def occurs(text: str, term: str) -> bool:
    """표기가 문서에 나오는가.

    정확 일치를 먼저 보고, 표기가 소문자로 시작할 때에 한해 **문장 첫머리
    위치의** 대문자 변형까지 본다. 문장 중간의 대문자는 보정하지 않는다.
    `Configuration is stored...`의 첫 낱말은 제품명이 아니지만 문장 중간의
    `React`는 프레임워크다.
    """
    if boundary_pattern(term).search(text):
        return True
    if not term[:1].islower():
        return False
    variant = term[0].upper() + term[1:]
    return any(
        is_sentence_start(text, m.start())
        for m in boundary_pattern(variant).finditer(text)
    )


def load_memo(path: Path) -> list[Entry]:
    if not path.exists():
        return []
    return [
        json.loads(line)
        for line in path.read_text(encoding="utf-8").splitlines()
        if line.strip()
    ]


def load_glossary(path: Path) -> dict[str, str]:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _fallback(
    glossary: dict[str, str], memo_terms: set[str], hit: Callable[[str], bool]
) -> list[Entry]:
    """메모장에 없는 표기만 신뢰도 낮은 후보로 올린다."""
    return [
        {"term": k, "ko": v, "confidence": "low"}
        for k, v in glossary.items()
        if k not in memo_terms and hit(k)
    ]


def lookup(
    text: str, memo: list[Entry], glossary: dict[str, str]
) -> dict[str, list[Entry]]:
    """문서에 실제로 나오는 표기의 후보를 두 소스에서 모은다."""
    memo_terms = {e["term"] for e in memo}
    return {
        "memo": [e for e in memo if occurs(text, e["term"])],
        "glossary": _fallback(glossary, memo_terms, lambda k: occurs(text, k)),
    }


def lookup_terms(
    terms: list[str], memo: list[Entry], glossary: dict[str, str]
) -> dict[str, list[Entry]]:
    """문서 매칭을 거치지 않고 표기를 직접 조회한다. 매칭이 놓친 것을 잡는다."""
    wanted = set(terms)
    memo_terms = {e["term"] for e in memo}
    return {
        "memo": [e for e in memo if e["term"] in wanted],
        "glossary": _fallback(glossary, memo_terms, lambda k: k in wanted),
    }


def append_entries(path: Path, entries: list[Entry], doc: str, date: str) -> int:
    """확정된 결정을 한 줄씩 덧붙인다. 기존 줄은 건드리지 않는다.

    맥락 없는 항목은 거절한다. 맥락이 이 설계의 존재 이유다.
    """
    rows = [
        {
            "term": e["term"],
            "ko": e["ko"],
            "context": e["context"],
            "doc": e.get("doc", doc),
            "date": e.get("date", date),
        }
        for e in _validated(entries)
    ]
    with path.open("a", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")

    load_memo(path)  # 모든 줄이 유효 JSON인지 검증
    return len(rows)


def _validated(entries: list[Entry]) -> list[Entry]:
    for entry in entries:
        missing = [k for k in ("term", "ko", "context") if not entry.get(k)]
        if missing:
            raise ValueError(f"필수 필드 누락 {missing}: {entry!r}")
    return entries


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    look = sub.add_parser("lookup", help="후보 표기를 조회한다")
    look.add_argument("input_file", nargs="?", type=Path)
    look.add_argument("--term", action="append", default=[], help="표기 직접 조회")
    look.add_argument("--memo", type=Path, default=DEFAULT_MEMO)
    look.add_argument("--glossary", type=Path, default=DEFAULT_GLOSSARY)

    rec = sub.add_parser("record", help="확정된 결정을 덧붙인다")
    rec.add_argument("entries", help='[{"term":..,"ko":..,"context":..}] JSON')
    rec.add_argument("--doc", required=True, help="번역한 문서 이름")
    rec.add_argument("--date", default=dt.date.today().isoformat())
    rec.add_argument("--memo", type=Path, default=DEFAULT_MEMO)

    return parser.parse_args(argv)


def _run_lookup(args: argparse.Namespace) -> int:
    memo = load_memo(args.memo)
    glossary = load_glossary(args.glossary)

    if args.term:
        result = lookup_terms(args.term, memo, glossary)
    elif args.input_file:
        result = lookup(args.input_file.read_text(encoding="utf-8"), memo, glossary)
    else:
        print("input_file 또는 --term 중 하나가 필요하다", file=sys.stderr)
        return 2

    print(json.dumps(result, ensure_ascii=False, indent=2))
    print(
        f"\n# memo {len(result['memo'])} candidates, "
        f"glossary {len(result['glossary'])} (low confidence)",
        file=sys.stderr,
    )
    return 0


def _run_record(args: argparse.Namespace) -> int:
    entries = json.loads(args.entries)
    if isinstance(entries, dict):
        entries = [entries]
    added = append_entries(args.memo, entries, doc=args.doc, date=args.date)
    print(f"recorded {added}")
    return 0


def main(argv: list[str] | None = None) -> int:
    args = _parse_args(sys.argv[1:] if argv is None else argv)
    return _run_lookup(args) if args.command == "lookup" else _run_record(args)


if __name__ == "__main__":
    raise SystemExit(main())
