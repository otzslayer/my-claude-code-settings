"""prescan.py 단위 테스트.

검사 대상은 산문 본문뿐이다. 코드 블록, 인라인 코드, URL, frontmatter는
마스킹되어 걸리지 않는다는 것이 이 스캐너의 정밀도를 지탱하는 조건이라
그 경계를 집중해서 검사한다.
"""

from __future__ import annotations

import prescan


def cats(text: str) -> list[str]:
    return [f.category for f in prescan.scan(text)]


def test_connective_ending_comma_is_flagged() -> None:
    assert "연결어미 뒤 쉼표" in cats("데이터를 정제하고, 모델을 학습시킨다.")
    assert "연결어미 뒤 쉼표" in cats("원문이 확정해 주므로, 되살릴 수 있다.")


def test_adverbial_lead_comma_is_flagged() -> None:
    assert "부사어 뒤 쉼표" in cats("따라서, 결과는 달라진다.")


def test_bare_list_comma_is_not_flagged() -> None:
    assert cats("취향, 뉘앙스, 소신이 갈린다.") == []


def test_em_dash_and_middle_dot_are_flagged() -> None:
    assert "줄표와 가운뎃점" in cats("완성된 산출물 — 코드와 문서 — 이 쌓인다.")
    assert "줄표와 가운뎃점" in cats("코드·문서·분석을 모은다.")


def test_double_particle_is_flagged() -> None:
    assert "이중 조사 결합" in cats("긴장으로부터의 해방을 말한다.")


def test_meta_entry_is_flagged() -> None:
    assert "메타 진입" in cats("이는 병목이 사람이라는 뜻이다.")


def test_meta_entry_needs_a_word_boundary() -> None:
    assert "메타 진입" not in cats("그 도구가 쓰이는 환경을 본다.")


def test_hedging_is_flagged() -> None:
    assert "hedging" in cats("지연이 줄어드는 것으로 보인다.")


def test_progressive_is_flagged() -> None:
    assert "진행형 자동 매핑" in cats("비용이 낮아지고 있다.")


def test_translationese_particle_is_flagged() -> None:
    assert "번역투 조사구" in cats("API를 통해 값을 읽는다.")


def test_lowercase_gloss_is_flagged() -> None:
    assert "영어 병기" in cats("사실(facts)만 남긴다.")


def test_proper_noun_gloss_is_not_flagged() -> None:
    assert "영어 병기" not in cats(
        "모델 컨텍스트 프로토콜(Model Context Protocol)이다."
    )


def test_inline_wikilink_without_alias_is_flagged() -> None:
    text = "그래서 [[#서버가 그려 보내는 사용자 인터페이스]]로 UI를 다룬다."
    assert "별칭 없는 위키링크" in cats(text)


def test_wikilink_with_alias_is_not_flagged() -> None:
    text = "그래서 [[#사용자 인터페이스 | MCP Apps]]로 UI를 다룬다."
    assert "별칭 없는 위키링크" not in cats(text)


def test_list_item_wikilink_is_not_flagged() -> None:
    assert "별칭 없는 위키링크" not in cats("- [[#사용자 인터페이스]]")


def test_code_fence_is_masked() -> None:
    text = "```python\n# 정제하고, 학습시킨다\nx = 1  # a — b\n```\n"
    assert cats(text) == []


def test_tilde_fence_is_masked() -> None:
    text = "~~~python\n# 정제하고, 학습시킨다\nx = 1  # a — b\n~~~\n"
    assert cats(text) == []


def test_fence_of_the_other_marker_does_not_close_the_block() -> None:
    text = "~~~\n정제하고, 학습한다\n```\n여전히 코드 안이다 — 그렇다\n~~~\n본문이다.\n"
    assert cats(text) == []


def test_inline_code_is_masked() -> None:
    assert cats("`정제하고, 학습한다`를 쓴다.") == []


def test_link_url_is_masked() -> None:
    assert cats("[문서](https://example.com/a—b·c)를 본다.") == []


def test_frontmatter_is_masked() -> None:
    text = "---\ntitle: A — B\ntags: [x·y]\n---\n\n본문이다.\n"
    assert cats(text) == []


def test_finding_carries_line_number_and_excerpt() -> None:
    text = "첫 줄이다.\n둘째 줄을 정제하고, 학습시킨다.\n"
    (finding,) = [f for f in prescan.scan(text) if f.category == "연결어미 뒤 쉼표"]
    assert finding.line == 2
    assert "정제하고," in finding.excerpt


def test_comma_budget_compares_against_the_source() -> None:
    budget = prescan.comma_budget("가, 나, 다, 라", "a, b")
    assert budget == (3, 1)


def test_report_names_every_category_that_fired() -> None:
    report = prescan.report(
        "따라서, 값이 낮아지고 있다.", source="Therefore, it falls."
    )
    assert "부사어 뒤 쉼표" in report
    assert "진행형 자동 매핑" in report


def test_report_says_clean_when_nothing_fires() -> None:
    assert "걸린 자리 없음" in prescan.report("값이 낮아진다.", source="It falls.")
