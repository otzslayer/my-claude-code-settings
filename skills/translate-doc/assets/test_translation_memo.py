"""translation_memo.py 단위 테스트.

메모장과 옛 글로서리를 tmp_path 픽스처로 주입해 실제 자산을 건드리지 않는다.
외부 동작(후보 조회 결과, append 후 파일 내용)만 검사한다.
"""

from __future__ import annotations

import json
from pathlib import Path

import translation_memo as tm

MEMO_LINES = [
    {
        "term": "ReAct",
        "ko": "ReAct",
        "context": "LLM 에이전트의 추론-행동 반복 프롬프팅 기법",
        "doc": "agentic-patterns.md",
        "date": "2026-08-12",
    },
    {
        "term": "alignment",
        "ko": "정렬",
        "context": "AI 안전 문맥. 모델 행동을 인간 의도에 맞추는 것",
        "doc": "safety.md",
        "date": "2026-08-12",
    },
    {
        "term": "alignment",
        "ko": "맞춤",
        "context": "UI 레이아웃 문맥. 요소의 정렬 위치",
        "doc": "design-system.md",
        "date": "2026-08-14",
    },
    {
        "term": "subagent",
        "ko": "서브에이전트",
        "context": "상위 에이전트가 위임하는 하위 에이전트",
        "doc": "agentic-patterns.md",
        "date": "2026-08-12",
    },
    {
        "term": "agent",
        "ko": "에이전트",
        "context": "도구를 호출하며 목표를 좇는 LLM 실행 단위",
        "doc": "agentic-patterns.md",
        "date": "2026-08-12",
    },
]

GLOSSARY = {
    "React": "React",
    "Docker": "Docker",
    "alignment": "얼라인먼트",
    "configuration": "설정",
}


def write_memo(path: Path, entries: list[dict[str, str]]) -> Path:
    path.write_text(
        "".join(json.dumps(e, ensure_ascii=False) + "\n" for e in entries),
        encoding="utf-8",
    )
    return path


def fixtures(tmp_path: Path) -> tuple[Path, Path]:
    memo = write_memo(tmp_path / "translation-memo.jsonl", MEMO_LINES)
    glossary = tmp_path / "glossary.json"
    glossary.write_text(json.dumps(GLOSSARY, ensure_ascii=False), encoding="utf-8")
    return memo, glossary


# ── 조회 ──────────────────────────────────────────────────────────────


def test_lookup_merges_memo_and_glossary(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "The ReAct loop runs inside Docker."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert [e["term"] for e in result["memo"]] == ["ReAct"]
    assert [e["term"] for e in result["glossary"]] == ["Docker"]


def test_lookup_is_case_sensitive(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "The ReAct pattern is not the React framework."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    # ReAct 문서에 React 항목이 딸려오지 않는다 (그 역도 마찬가지).
    assert [e["term"] for e in result["memo"]] == ["ReAct"]
    # React는 원문에 실제로 있으므로 글로서리 후보로는 나온다.
    assert [e["term"] for e in result["glossary"]] == ["React"]


def test_lookup_case_sensitivity_excludes_absent_spelling(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "The ReAct pattern drives the loop."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert result["glossary"] == []


def test_sentence_start_capital_is_folded(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "Alignment is hard."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert {e["ko"] for e in result["memo"]} == {"정렬", "맞춤"}


def test_markdown_line_lead_counts_as_sentence_start(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "## Alignment\n\n- Agent behaviour\n"

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert {e["term"] for e in result["memo"]} == {"alignment", "agent"}


def test_mid_sentence_capital_is_not_folded(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "We treat Alignment as a product name here."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert result["memo"] == []


def test_plural_matches_but_prefix_does_not(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)

    plural = tm.lookup("Spawn subagents for the sweep.", tm.load_memo(memo), {})
    assert [e["term"] for e in plural["memo"]] == ["subagent"]

    prefix = tm.lookup("This is an agentic workflow.", tm.load_memo(memo), {})
    assert prefix["memo"] == []


def test_polysemous_term_yields_every_line(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "The alignment of the two panes matters."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert [e["ko"] for e in result["memo"]] == ["정렬", "맞춤"]
    assert [e["context"] for e in result["memo"]] == [
        MEMO_LINES[1]["context"],
        MEMO_LINES[2]["context"],
    ]


def test_glossary_candidates_are_marked_low_confidence(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "Run it in Docker."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert result["glossary"] == [
        {"term": "Docker", "ko": "Docker", "confidence": "low"}
    ]
    assert all("confidence" not in e for e in result["memo"])


def test_glossary_defers_to_memo_for_the_same_term(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)
    text = "The alignment problem is unsolved."

    result = tm.lookup(text, tm.load_memo(memo), tm.load_glossary(glossary))

    assert [e["term"] for e in result["glossary"]] == []
    assert [e["term"] for e in result["memo"]] == ["alignment", "alignment"]


def test_ad_hoc_term_lookup_ignores_the_document(tmp_path: Path) -> None:
    memo, glossary = fixtures(tmp_path)

    result = tm.lookup_terms(
        ["alignment", "React"], tm.load_memo(memo), tm.load_glossary(glossary)
    )

    assert [e["ko"] for e in result["memo"]] == ["정렬", "맞춤"]
    assert result["glossary"] == [{"term": "React", "ko": "React", "confidence": "low"}]


# ── 기록 ──────────────────────────────────────────────────────────────


def test_record_appends_one_line_and_leaves_the_rest(tmp_path: Path) -> None:
    memo, _ = fixtures(tmp_path)
    before = memo.read_text(encoding="utf-8")

    tm.append_entries(
        memo,
        [{"term": "RAG", "ko": "RAG", "context": "검색 증강 생성"}],
        doc="rag.md",
        date="2026-08-15",
    )

    after = memo.read_text(encoding="utf-8")
    assert after.startswith(before)
    assert len(after.splitlines()) == len(before.splitlines()) + 1


def test_record_keeps_korean_unescaped(tmp_path: Path) -> None:
    memo, _ = fixtures(tmp_path)

    tm.append_entries(
        memo,
        [
            {
                "term": "RAG",
                "ko": "검색 증강 생성(RAG)",
                "context": "검색으로 문맥을 채우는 기법",
            }
        ],
        doc="rag.md",
        date="2026-08-15",
    )

    assert "검색 증강 생성(RAG)" in memo.read_text(encoding="utf-8")
    assert "\\u" not in memo.read_text(encoding="utf-8")


def test_record_adds_a_new_line_for_a_new_sense(tmp_path: Path) -> None:
    memo, _ = fixtures(tmp_path)

    tm.append_entries(
        memo,
        [{"term": "alignment", "ko": "행 맞춤", "context": "표 조판 문맥"}],
        doc="typesetting.md",
        date="2026-08-15",
    )

    entries = tm.load_memo(memo)
    assert [e["ko"] for e in entries if e["term"] == "alignment"] == [
        "정렬",
        "맞춤",
        "행 맞춤",
    ]


def test_record_leaves_every_line_valid_json(tmp_path: Path) -> None:
    memo, _ = fixtures(tmp_path)

    tm.append_entries(
        memo,
        [
            {"term": "MCP", "ko": "MCP", "context": "도구 연결 프로토콜"},
            {
                "term": "KV cache",
                "ko": "KV 캐시",
                "context": "어텐션 키-값 재사용 버퍼",
            },
        ],
        doc="protocols.md",
        date="2026-08-15",
    )

    for line in memo.read_text(encoding="utf-8").splitlines():
        assert set(json.loads(line)) == {"term", "ko", "context", "doc", "date"}


def test_record_rejects_an_entry_without_context(tmp_path: Path) -> None:
    memo, _ = fixtures(tmp_path)
    before = memo.read_text(encoding="utf-8")

    try:
        tm.append_entries(
            memo, [{"term": "RAG", "ko": "RAG"}], doc="rag.md", date="2026-08-15"
        )
    except ValueError:
        pass
    else:
        raise AssertionError("context 없는 항목이 통과했다")

    assert memo.read_text(encoding="utf-8") == before


def test_record_creates_the_memo_when_absent(tmp_path: Path) -> None:
    memo = tmp_path / "fresh.jsonl"

    tm.append_entries(
        memo,
        [{"term": "MCP", "ko": "MCP", "context": "도구 연결 프로토콜"}],
        doc="protocols.md",
        date="2026-08-15",
    )

    assert len(tm.load_memo(memo)) == 1
