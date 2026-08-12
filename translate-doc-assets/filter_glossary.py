#!/usr/bin/env python3
"""입력 문서에 실제로 등장하는 글로서리 항목만 추려 JSON으로 내보낸다.

/translate-doc Step 2가 쓴다. 글로서리 전체(2,400여 항목, 110K자)를 Read하면
Read 도구의 2,000줄 한도에 걸려 뒤쪽 항목이 조용히 잘리므로, 파일을 읽는 대신
이 스크립트의 출력만 컨텍스트에 넣는다.

사용법: python3 filter_glossary.py <input_file> [glossary_path]
"""

import json
import re
import sys
from pathlib import Path

DEFAULT_GLOSSARY = Path(__file__).with_name("glossary.json")


def boundary_pattern(key: str) -> re.Pattern[str]:
    """단어 경계 위에서만 매칭한다. `agent`가 `agentic`에 걸리지 않게 한다.

    영어 복수형 접미사(`-s`/`-es`)는 허용한다. 그것까지 막으면 `subagents`가
    `subagent`에 걸리지 않아 실제 용어를 놓친다. `agentic`은 여전히 배제된다.

    키가 비영숫자로 시작하거나 끝나면 그쪽 경계는 붙이지 않는다.
    `(LLM)` 같은 괄호 표기가 통째로 탈락하는 것을 막는다.
    """
    prefix = r"(?<![A-Za-z0-9])" if key[:1].isalnum() else ""
    suffix = r"(?:e?s)?(?![A-Za-z0-9])" if key[-1:].isalnum() else ""
    return re.compile(prefix + re.escape(key) + suffix, re.IGNORECASE)


def filter_glossary(text: str, glossary: dict[str, str]) -> dict[str, str]:
    return {k: v for k, v in glossary.items() if boundary_pattern(k).search(text)}


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    text = Path(sys.argv[1]).read_text(encoding="utf-8")
    glossary_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_GLOSSARY
    glossary = json.loads(glossary_path.read_text(encoding="utf-8"))

    hits = filter_glossary(text, glossary)
    print(json.dumps(hits, ensure_ascii=False, indent=2))
    print(f"\n# {len(hits)} / {len(glossary)} terms matched", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
