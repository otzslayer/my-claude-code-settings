"""resync_translationese.py 단위 테스트.

I/O(fetch)는 monkeypatch로 차단하고 순수 함수(parse/diff)를 fixture
문자열로 검증한다. 분할 self-check는 동결 fixture로 U1 ledger를 잠근다.
"""

from __future__ import annotations

import urllib.error
from pathlib import Path

import resync_translationese as rt

FIXTURE = Path(__file__).with_name("testdata") / "ai-tell-taxonomy.807172.md"

TAXONOMY_SNIPPET = """\
## A. 번역투 (Translation-ese) — S1~S2

### A-1. "~에 대하여" 남발 [S1]
- 패턴: about/regarding 직역

### A-15. 추상 주어 + 만능 동사 [S2] · v1.1 신규
- 패턴: The X shows Y 직역

### A-17. (보류 — v2.0 hold) 무정물·추상명사 '-들' 부착
> Hold 사유: 외부 회차 양성 0건.

### E-7. 청자 경어법 일관성 손실 (해라/하게체) [S2 · estimated] · v2.0 신규
- 패턴: 격식 단계 혼재

## 탐지 출력 스키마 (Detector → Rewriter 공유 계약)

### 버전 관리
- 일반 텍스트의 헤딩은 ID 패턴이 아니므로 무시한다.
"""

LEDGER_MD = """\
---
source: epoko77-ai/im-not-ai
pinned_commit: "807172694d75"
# 주석 라인은 무시된다
absorbed: [C-11, A-7, "PE15"]
already_covered: [A-1, A-2]
excluded: [C-1, A-17]
deferred: [C-7, B-4]
---

# 본문
absorbed: [should, not, parse]
"""


# ── parse_ids (KTD-3 ID-first, severity-second) ──────────────────────


def test_parse_ids_extracts_severity_variants() -> None:
    ids = rt.parse_ids(TAXONOMY_SNIPPET)
    assert set(ids) == {"A-1", "A-15", "A-17", "E-7"}
    assert ids["A-1"] == "S1"
    assert ids["A-15"] == "S2"
    assert ids["E-7"] == "S2"  # [S2 · estimated] → S2


def test_parse_ids_a17_hold_has_no_severity() -> None:
    # "### A-17. ... (HOLD)" — 원래 spec regex가 깨지던 라인.
    # severity-optional의 이유를 이름으로 고정해 문서화한다.
    ids = rt.parse_ids(TAXONOMY_SNIPPET)
    assert ids["A-17"] is None


# ── parse_ledger ─────────────────────────────────────────────────────


def test_parse_ledger_extracts_lists_and_commit() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    assert led.pinned_commit == "807172694d75"
    assert led.absorbed == ["C-11", "A-7", "PE15"]
    assert led.already_covered == ["A-1", "A-2"]
    assert led.excluded == ["C-1", "A-17"]
    assert led.deferred == ["C-7", "B-4"]


def test_pe15_preserved_but_excluded_from_aj_union() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    assert "PE15" in led.absorbed  # ledger 객체에 보존
    assert "PE15" not in led.aj_union()  # A-J union에서 제외


def test_pe15_never_in_report_diff() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    ids = {"C-11": "S1", "A-7": "S1"}
    report = rt.build_report(led, ids, ids, "deadbeef0000", "2026-01-01")
    assert "PE15" not in report


# ── 분할 self-check (U1 ledger 잠금, 동결 fixture) ────────────────────


def test_ledger_partition_matches_frozen_fixture() -> None:
    fixture = FIXTURE.read_text(encoding="utf-8")
    patterns_path = FIXTURE.parent.parent / "translationese-patterns.md"
    ledger_md = patterns_path.read_text(encoding="utf-8")
    led = rt.parse_ledger(ledger_md)
    fixture_ids = set(rt.parse_ids(fixture))
    assert len(fixture_ids) == 71
    assert led.aj_union() == fixture_ids


# ── build_report 4종 리포트 ──────────────────────────────────────────


def test_new_id_appears_in_review_section() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    ids_head = {"C-11": "S1", "A-20": "S2"}  # A-20: union 밖
    report = rt.build_report(led, {"C-11": "S1"}, ids_head, "x", "d")
    assert "신규 ID" in report
    assert "A-20" in report


def test_severity_change_appears_in_reeval_section() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    report = rt.build_report(led, {"A-7": "S2"}, {"A-7": "S1"}, "x", "d")
    section2 = report.split("[2]")[1].split("[3]")[0]
    assert "A-7" in section2
    assert "S2 → S1" in section2


def test_deferred_escalation_appears_in_unhold_section() -> None:
    led = rt.parse_ledger(LEDGER_MD)  # deferred = [C-7, B-4]
    report = rt.build_report(led, {"C-7": "S2"}, {"C-7": "S1"}, "x", "d")
    section3 = report.split("[3]")[1].split("[4]")[0]
    assert "C-7" in section3


def test_deferred_none_to_severity_escalates() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    report = rt.build_report(led, {"B-4": None}, {"B-4": "S2"}, "x", "d")
    section3 = report.split("[3]")[1].split("[4]")[0]
    assert "B-4" in section3


def test_deferred_deescalation_not_reported() -> None:
    # S1 → S2 는 약화이므로 '보류 해제 검토'에 등장하면 안 된다.
    # (severity 방향이 거꾸로면 여기서 잡힌다 — 조용히 틀리면 비쌈.)
    led = rt.parse_ledger(LEDGER_MD)
    report = rt.build_report(led, {"C-7": "S1"}, {"C-7": "S2"}, "x", "d")
    section3 = report.split("[3]")[1].split("[4]")[0]
    assert "C-7" not in section3


def test_version_change_reported() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    report = rt.build_report(led, {}, {}, "abcdef123456", "2026-06-01")
    section4 = report.split("[4]")[1]
    assert "버전 변경" in report
    assert "807172694d75" in section4


def test_version_same_when_pinned_equals_head() -> None:
    led = rt.parse_ledger(LEDGER_MD)
    report = rt.build_report(led, {}, {}, "807172694d75", "d")
    section4 = report.split("[4]")[1]
    assert "변경 없음" in section4


def test_version_same_when_pinned_is_short_prefix_of_head() -> None:
    # pinned는 12자 short SHA, gh는 40자 full SHA를 준다. prefix 일치면 동일.
    led = rt.parse_ledger(LEDGER_MD)  # pinned = 807172694d75
    full_head = "807172694d75aaaa1111bbbb2222cccc3333dddd"
    report = rt.build_report(led, {}, {}, full_head, "d")
    section4 = report.split("[4]")[1]
    assert "변경 없음" in section4


# ── main 오케스트레이션 (sanity floor · graceful errors) ──────────────


def test_main_aborts_on_sanity_floor(monkeypatch, capsys) -> None:
    monkeypatch.setattr(rt, "fetch_head_commit", lambda: ("headsha000000", "d"))
    monkeypatch.setattr(rt, "fetch_taxonomy", lambda _ref: "### A-1. x [S1]\n")
    rc = rt.main()
    assert rc == 1
    assert "중단" in capsys.readouterr().err


def test_main_graceful_when_gh_missing(monkeypatch, capsys) -> None:
    def _missing() -> tuple[str, str]:
        raise FileNotFoundError("gh")

    monkeypatch.setattr(rt, "fetch_head_commit", _missing)
    rc = rt.main()
    err = capsys.readouterr().err
    assert rc == 1
    assert "gh" in err
    assert "Traceback" not in err


def test_main_graceful_on_malformed_gh_json(monkeypatch, capsys) -> None:
    def _bad_shape() -> tuple[str, str]:
        raise KeyError("commit")  # gh가 exit 0이나 예상 키 부재

    monkeypatch.setattr(rt, "fetch_head_commit", _bad_shape)
    rc = rt.main()
    err = capsys.readouterr().err
    assert rc == 1
    assert "예상과 다릅니다" in err
    assert "Traceback" not in err


def test_main_graceful_on_network_error(monkeypatch, capsys) -> None:
    def _no_net(ref: str) -> str:
        raise urllib.error.URLError("no network")

    monkeypatch.setattr(rt, "fetch_head_commit", lambda: ("headsha000000", "d"))
    monkeypatch.setattr(rt, "fetch_taxonomy", _no_net)
    rc = rt.main()
    err = capsys.readouterr().err
    assert rc == 1
    assert "네트워크" in err
    assert "Traceback" not in err
