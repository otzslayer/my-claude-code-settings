#!/usr/bin/env python3
"""번역본에서 기계로 셀 수 있는 번역투 후보를 뽑는다.

Step 5의 눈으로 훑는 점검은 자기가 방금 쓴 글을 자기가 보는 자리라 표면
패턴을 놓친다. 이 스캐너는 정규식으로 셀 수 있는 것만 맡아 그 사각을 메운다.

**결과는 후보일 뿐 판정이 아니다.** 특히 쉼표는 어문 규범이 요구하는 자리
(SKILL.md "쉼표 절제"의 (e))가 있어 걸린 것을 그대로 지우면 문장이 잘못
읽힌다. 지울지는 원문과 문맥을 든 번역자가 정한다.

검사 대상은 산문 본문뿐이다. frontmatter, 코드 블록, 인라인 코드, URL은
마스킹되어 걸리지 않는다.

사용법:
    python3 prescan.py <translated_file> --source <source_file>
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

EXCERPT_PAD = 18


@dataclass(frozen=True)
class Finding:
    """걸린 자리 하나. `line`은 1부터 센다."""

    category: str
    line: int
    excerpt: str


# 문장 첫머리에서 쉼표를 달고 나오는 접속부사와 부사어.
ADVERBIALS = (
    "그러나|하지만|따라서|그래서|또한|그리고|즉|물론|사실|실제로|다만|반면"
    "|한편|결국|먼저|우선|특히|예를 들어|다시 말해|무엇보다|오히려|게다가"
    "|심지어|대신|반대로|이때|그러면|그런데|어쨌든|솔직히|분명히|확실히"
)

# 순서가 곧 우선순위다. 구간이 겹치면 앞선 항목만 남는다.
PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("부사어 뒤 쉼표", re.compile(rf"(?:^|(?<=[.!?]\s))(?:{ADVERBIALS}),")),
    (
        "연결어미 뒤 쉼표",
        re.compile(r"[가-힣](?:고|며|지만|면서|아서|어서|는데|므로|자),"),
    ),
    ("줄표와 가운뎃점", re.compile(r"[—–·]")),
    (
        "이중 조사 결합",
        re.compile(r"(?:에서의|에로의|으로의|에의|으로부터의|로부터의)"),
    ),
    (
        "메타 진입",
        # 어절 첫머리에서만 본다. `쓰이는 환경`의 꼬리가 `이는 `으로 걸린다.
        re.compile(r"(?<![가-힣])(?:이는 |이 점에서|이 관점에서 보면|이 말은 )"),
    ),
    (
        "hedging",
        re.compile(
            r"(?:것으로 보인다|로 보인다|인 듯하다|로 판단된다"
            r"|수 있을 것으로|보여질|가능성이 있을)"
        ),
    ),
    ("진행형 자동 매핑", re.compile(r"[가-힣]고 있(?:다|는|었|어|으며)")),
    (
        "번역투 조사구",
        re.compile(
            r"(?:를 통해|을 통해|에 대해|에 대한|에 의해|되어지"
            r"|함으로써|에 있어|에 기반하여|와 관련하여|과 관련하여)"
        ),
    ),
    ("영어 병기", re.compile(r"[가-힣]\([a-z][A-Za-z ]*\)")),
    ("별칭 없는 위키링크", re.compile(r"(?<=[^\s\-*+])\s*\[\[#[^\]|]+\]\]")),
)

INLINE_MASKED = re.compile(r"`[^`]*`|\]\([^)]*\)|https?://\S+")


def _blank(match: re.Match[str]) -> str:
    """길이를 보존한 채 지운다. 행과 열 번호가 원문과 그대로 맞아야 한다."""
    return " " * len(match.group())


def _fence_marker(line: str) -> str | None:
    """이 줄이 코드 펜스를 여닫는가. 여는 문자를 그대로 돌려준다."""
    stripped = line.lstrip()
    return next((m for m in ("```", "~~~") if stripped.startswith(m)), None)


def mask(text: str) -> str:
    """산문이 아닌 구간을 공백으로 덮는다. 글자 수는 그대로 둔다.

    네 칸 들여쓴 코드 블록은 마스킹하지 않는다. 목록 항목의 이어지는 줄과
    구별되지 않아 산문을 덮을 위험이 크다. 번역 대상 문서는 펜스를 쓴다.
    """
    masked: list[str] = []
    fence: str | None = None
    in_frontmatter = False

    for index, line in enumerate(text.split("\n")):
        blanked = " " * len(line)
        marker = _fence_marker(line)
        if index == 0 and line.strip() == "---":
            in_frontmatter = True
            masked.append(blanked)
        elif in_frontmatter:
            in_frontmatter = line.strip() != "---"
            masked.append(blanked)
        elif fence is not None:
            fence = None if marker == fence else fence
            masked.append(blanked)
        elif marker is not None:
            fence = marker
            masked.append(blanked)
        else:
            masked.append(INLINE_MASKED.sub(_blank, line))

    return "\n".join(masked)


def _excerpt(line: str, start: int, end: int) -> str:
    left = max(0, start - EXCERPT_PAD)
    right = min(len(line), end + EXCERPT_PAD)
    head = "…" if left > 0 else ""
    tail = "…" if right < len(line) else ""
    return f"{head}{line[left:right].strip()}{tail}"


def _scan_line(number: int, raw: str, masked: str) -> list[Finding]:
    findings: list[Finding] = []
    taken: list[range] = []

    for category, pattern in PATTERNS:
        for match in pattern.finditer(masked):
            span = range(match.start(), match.end())
            if any(span.start < seen.stop and seen.start < span.stop for seen in taken):
                continue
            taken.append(span)
            findings.append(
                Finding(category, number, _excerpt(raw, match.start(), match.end()))
            )

    return findings


def scan(text: str) -> list[Finding]:
    """산문 본문에서 후보를 뽑는다. 겹치는 자리는 우선순위가 높은 하나만 남는다."""
    raw_lines = text.split("\n")
    masked_lines = mask(text).split("\n")
    return [
        finding
        for number, (raw, masked) in enumerate(zip(raw_lines, masked_lines), start=1)
        for finding in _scan_line(number, raw, masked)
    ]


def comma_budget(translated: str, source: str) -> tuple[int, int]:
    """번역본과 원문의 쉼표 수를 센다. 번역본이 원문을 넘기지 않아야 한다."""
    return mask(translated).count(","), mask(source).count(",")


def report(translated: str, source: str) -> str:
    """사람이 읽을 후보 목록. 카테고리별로 묶고 건수를 앞세운다."""
    used, allowed = comma_budget(translated, source)
    verdict = "초과" if used > allowed else "이내"
    lines = [f"쉼표: 번역 {used} / 원문 {allowed} ({verdict})", ""]

    findings = scan(translated)
    if not findings:
        lines.append("걸린 자리 없음")
        return "\n".join(lines)

    for category, _ in PATTERNS:
        hits = [f for f in findings if f.category == category]
        if not hits:
            continue
        lines.append(f"{category} {len(hits)}건")
        lines.extend(f"  L{f.line}  {f.excerpt}" for f in hits)
        lines.append("")

    lines.append("모두 후보다. 어문 규범이 요구하는 자리인지 원문과 함께 판정한다.")
    return "\n".join(lines)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("translated_file", type=Path, help="번역본 경로")
    parser.add_argument("--source", type=Path, required=True, help="영어 원문 경로")
    args = parser.parse_args(sys.argv[1:] if argv is None else argv)

    print(
        report(
            args.translated_file.read_text(encoding="utf-8"),
            args.source.read_text(encoding="utf-8"),
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
