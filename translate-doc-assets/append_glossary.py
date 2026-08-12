#!/usr/bin/env python3
"""새 기술 고유명사를 글로서리 끝에 덧붙인다. 기존 키는 덮어쓰지 않는다.

/translate-doc Step 7이 쓴다. 글로서리는 외부 저장소로 가는 심링크라
전체 재직렬화가 무관한 diff를 남기므로, 줄 단위로만 덧붙인다.

사용법: python3 append_glossary.py '{"Term": "번역"}' [glossary_path]
"""

import json
import sys
from pathlib import Path

DEFAULT_GLOSSARY = Path(__file__).with_name("glossary.json")


def dump(value: str) -> str:
    """한국어를 \\uXXXX로 이스케이프하지 않고 그대로 직렬화한다."""
    return json.dumps(value, ensure_ascii=False)


def render(entries: dict[str, str]) -> list[str]:
    return [f"  {dump(k)}: {dump(v)}," for k, v in entries.items()]


def append(path: Path, new_terms: dict[str, str]) -> tuple[int, int]:
    existing = json.loads(path.read_text(encoding="utf-8"))
    fresh = {k: v for k, v in new_terms.items() if k not in existing}
    if not fresh:
        return 0, len(new_terms)

    lines = path.read_text(encoding="utf-8").rstrip("\n").split("\n")
    if lines[-1] != "}":
        raise ValueError(f"예상 밖의 마지막 줄: {lines[-1]!r}")

    body = render(fresh)
    body[-1] = body[-1].rstrip(",")
    merged = [*lines[:-1], *body, "}"]
    merged[len(lines) - 2] += ","

    path.write_text("\n".join(merged) + "\n", encoding="utf-8")
    json.loads(path.read_text(encoding="utf-8"))  # 유효 JSON인지 검증
    return len(fresh), len(new_terms) - len(fresh)


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    new_terms = json.loads(sys.argv[1])
    path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_GLOSSARY
    added, skipped = append(path, new_terms)
    print(f"added {added}, skipped {skipped} (already present)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
