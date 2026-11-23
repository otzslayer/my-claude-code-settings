#!/usr/bin/env python3
"""한국어 마크다운 문서를 점검한다.

사용법: python3 check.py <문서.md> [--rare N]

찾는 것:
  1. 각주 짝: 본문의 [^키]와 정의 [^키]: 가 맞는지
  2. 금지 부호: 줄표(—), 붙임표(–), 가운뎃점(·)
  3. 연결어미 뒤 쉼표 후보: 규범이 요구하는 자리인지는 사람이 판정한다
  4. '의' 연쇄: 'A의 B의 C'처럼 '의'가 가깝게 이어진 자리
  5. 드물게 나온 음절: 문서에 N번 이하(기본 2번) 나온 음절과 첫 등장 문맥.
     긴 글을 쓰다 생긴 음절 오타(나뉩니다 → 나늉니다)는 대개 이 목록에 나온다.

프런트매터, 코드 블록, 인라인 코드, URL은 검사하지 않는다.
"""
import collections
import re
import sys

CONNECTIVE_COMMA = re.compile(r"[가-힣]*(?:고|며|지만|면서|아서|어서|해서|여서|는데|은데|니까)(?=,)")
UI_CHAIN = re.compile(r"[가-힣]의\s+\S{1,8}의\s")
FORBIDDEN = {"—": "줄표", "–": "붙임표", "·": "가운뎃점"}


def strip_noise(text: str) -> str:
    """검사하지 않을 부분을 지우되 줄 수는 유지해 행 번호가 원문과 맞게 한다."""
    keep_lines = lambda m: "\n" * m.group(0).count("\n")
    text = re.sub(r"\A---\n.*?\n---\n", keep_lines, text, flags=re.S)
    text = re.sub(r"```.*?```", keep_lines, text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", "", text)
    text = re.sub(r"<https?://[^>]+>", "", text)
    text = re.sub(r"\]\(https?://[^)]+\)", "]", text)
    text = re.sub(r"https?://\S+", "", text)
    return text


def line_no(full: str, needle_pos: int) -> int:
    return full.count("\n", 0, needle_pos) + 1


def main() -> int:
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 2
    rare_max = 2
    if "--rare" in args:
        i = args.index("--rare")
        rare_max = int(args[i + 1])
        del args[i : i + 2]
    path = args[0]
    raw = open(path, encoding="utf-8").read()
    body = strip_noise(raw)
    lines = body.split("\n")
    problems = 0

    # 1. 각주 짝
    used = set(re.findall(r"\[\^([^\]]+)\](?!:)", raw))
    defined = set(re.findall(r"^\[\^([^\]]+)\]:", raw, flags=re.M))
    missing, unused = sorted(used - defined), sorted(defined - used)
    print("## 1. 각주 짝")
    if missing:
        print(f"- 정의가 없는 각주: {', '.join(missing)}")
    if unused:
        print(f"- 본문에서 쓰지 않는 정의: {', '.join(unused)}")
    if not missing and not unused:
        print("- 문제 없음")
    problems += len(missing) + len(unused)

    # 2. 금지 부호
    print("\n## 2. 금지 부호")
    found = False
    for n, line in enumerate(lines, 1):
        for ch, name in FORBIDDEN.items():
            if ch in line:
                found = True
                problems += 1
                print(f"- {n}행 {name}: {line.strip()[:80]}")
    if not found:
        print("- 문제 없음")

    # 3. 연결어미 뒤 쉼표 후보
    print("\n## 3. 연결어미 뒤 쉼표 후보 (규범이 요구하는 자리인지 판정. 표 안의 '고치기 전' 예문도 걸린다)")
    found = False
    for n, line in enumerate(lines, 1):
        if line.lstrip().startswith("[^"):
            continue
        for m in CONNECTIVE_COMMA.finditer(line):
            found = True
            s = line[max(0, m.start() - 15) : m.end() + 15]
            print(f"- {n}행: …{s.strip()}…")
    if not found:
        print("- 후보 없음")

    # 4. '의' 연쇄: 'A의 B의 C'처럼 '의'가 가깝게 이어진 자리
    print("\n## 4. '의' 연쇄 ('A의 B의 C'처럼 가깝게 이어진 자리)")
    found = False
    for n, line in enumerate(lines, 1):
        if line.lstrip().startswith(("[^", "#")):
            continue
        for m in UI_CHAIN.finditer(line):
            found = True
            s = line[max(0, m.start() - 10) : m.end() + 10]
            print(f"- {n}행: …{s.strip()}…")
    if not found:
        print("- 없음")

    # 5. 드물게 나온 음절
    prose = "\n".join(l for l in lines if not l.lstrip().startswith("[^"))
    counts = collections.Counter(ch for ch in prose if "가" <= ch <= "힣")
    rare = sorted(ch for ch, c in counts.items() if c <= rare_max)
    print(f"\n## 5. 드물게 나온 음절 ({rare_max}번 이하, {len(rare)}개): 오타가 없는지 끝까지 읽는다")
    for ch in rare:
        pos = prose.index(ch)
        ctx = prose[max(0, pos - 8) : pos + 8].replace("\n", " ")
        print(f"- {ch} ({counts[ch]}) {line_no(prose, pos)}행: {ctx}")

    print(f"\n요약: 자동 판정 문제 {problems}건, 쉼표와 '의'와 음절 목록은 사람이 판정")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
