#!/usr/bin/env bash
# hybrid-workflow.md 7단계 파이프라인 진입 시, Skill 호출 직후 단계별 지침을 주입한다.
# matcher:"Skill"로 모든 스킬 호출에 발동하지만, case에 없는 스킬은 clean no-op(출력 없음, exit 0).
# 모델·effort 전환은 메인 에이전트가 세션 중 스스로 못 하므로,
# 주입 내용은 "announce + 사용자에게 전환 안내"이며 강제가 아니라 강한 넛지다.
#
# salience 보존: brainstorming opener는 full 문단으로 둔다.
# ce-plan은 non-plan-mode 본작업 + plannotator 브라켓 안내가 필요해 의도적으로 격상해 multi-sentence로 둔다.
# 그 외 자주 호출되는 단계는 terse 1줄로 유지한다(additionalContext 습관화 → opener 희석 방지).
# model·effort는 단계 고정이 아니라 복잡도 채점(hybrid-workflow.md 3장)으로 산출한다 — 각 case는 그 채점 산출을 announce하라는 짧은 포인터만 담는다.

input=$(cat)
# python3 json parse (not grep -P / sed regex): settings.json fires this via a non-interactive
# `bash script.sh` subshell, where grep resolves to BSD grep (no -P support) — PCRE would
# silently no-op every case. A regex extraction (grep -P or sed's greedy .*"skill") is also
# unsafe here: tool_response can itself contain a nested "skill" key (e.g. ce-plan's own
# tool_response), and a greedy/leftmost-unaware pattern can grab that instead of the real
# tool_input.skill. Real JSON parsing sidesteps both problems.
skill=$(printf '%s' "$input" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("skill", ""))
except Exception:
    pass')

emit() {
  # $1: additionalContext 텍스트. 내부에 큰따옴표(") 사용 금지 — JSON이 깨진다.
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$1"
}

case "$skill" in
  *brainstorming)
    emit "BRAINSTORMING STARTED — MANDATORY FIRST TURN: rules/hybrid-workflow.md의 95퍼센트 confidence opener 규칙에 따라, 일반적인 무엇을 만들까요 식 질문 대신 반드시 다음 opener로 첫 turn을 시작하라 → 지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95퍼센트 확신이 생길 때까지 질문을 던지겠습니다, 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다. 이후 한 번에 한 질문 원칙으로 95퍼센트 확신까지 반복하고, 그 미만에서 설계 단계로 넘어가지 말 것. 제품성 작업이면 evidence·specificity·counterfactual·attachment·durability 5렌즈로 질문을 도출하라. 브레인스토밍 종료 시 superpowers가 writing-plans 호출을 안내해도 따르지 말고 /clear 후 /ce-plan으로 진행하라(이 파이프라인은 writing-plans 미사용). ce-plan 본작업은 non-plan-mode에서 호출하라(Plan Mode 진입 불필요 — Plan Mode는 ce-plan의 Write·autofix를 차단한다)." ;;
  *ce-plan)
    emit "Phase 2 PLAN: non-plan-mode에서 실행하라(Plan Mode가 ce-plan의 계획 파일 Write와 ce-doc-review autofix를 차단하므로). model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하라 — 계획 수립은 대개 개방형 추론(base 5) 이상이라 opus 밴드에 해당할 가능성이 높다. 병렬 리서치+CodeGraph 패턴 수집, docs/solutions/ 파일 3개 이상이면 ce-learnings-researcher 조회. docs/plans/ 초안 Write → 자동 ce-doc-review(hybrid-workflow.md 5장 리뷰어 분기) → 편집 없는 EnterPlanMode 후 즉시 ExitPlanMode 브라켓(finalized 계획을 인자로)으로 plannotator 하드 게이트를 재발동하고, 브라우저 승인 후에만 /clear하라. 브라켓이 막히면 plannotator-annotate 스킬로 대체." ;;
  *ce-doc-review)
    emit "DOC REVIEW(ce-plan 내부 5.3.8): 리뷰어 7종 중 adversarial·security-lens는 Agent 도구 model:opus로, 나머지(coherence·feasibility·product-lens·design-lens·scope-guardian)는 model:sonnet으로 dispatch하라(hybrid-workflow.md 5장). SKILL.md의 parent-상속 지시는 무시하고 이 분기를 강제한다 — effort는 dispatch로 지정 불가하므로 세션에서 상속된다. 세션 모델은 전환 금지(캐시 재로딩 비용). 다음 단계: 편집 없는 EnterPlanMode 후 즉시 ExitPlanMode 브라켓으로 plannotator 하드 게이트를 재발동하라(브라우저 승인 전 /clear 금지)." ;;
  *test-driven-development)
    emit "Phase 2-prime BUILD(TDD): model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하고 현재 세션과 다르면 전환 안내(강제 아님). RED→GREEN→REFACTOR, 트리비얼 면제." ;;
  *ce-work)
    emit "Phase 2-prime BUILD(ce-work): model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하고 현재 세션과 다르면 전환 안내(강제 아님). 확정 plan 실행, CodeGraph 심볼 편집 우선. 완료(구현+테스트) 후 인라인 종료 금지 — hybrid-workflow Phase 2-prime step3에 따라 반드시 다음 단계 /ce-code-review를 사용자에게 안내하라(ce-work 내부 Tier1 review와 별개로 항상 수행)." ;;
  *ce-code-review)
    emit "Phase 2-prime REVIEW: 세션 모델 전환 금지(캐시 재로딩 비용). 리뷰어 중 correctness·security·adversarial은 model:opus, 나머지는 model:sonnet으로 dispatch하라(hybrid-workflow.md 5장). 리뷰·수정 완료 후 다음 단계 verification-before-completion으로 진행." ;;
  *verification-before-completion)
    emit "Phase 3 VERIFY: model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하라(검증은 대개 기계적 base라 낮은 밴드). uv run ty check·ruff check --fix·ruff format·pytest -v 실제 실행 후 출력으로 확인하고 완료 선언(증거 우선). 검증 통과 후 다음 단계 ce-compound(mode:headless)로 진행." ;;
  *ce-compound)
    emit "Phase 3 LEARN: model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하라. mode:headless, docs/solutions/만 생성(콘텐츠 한국어, frontmatter 키·enum 영문). Tier 0/1 자동 반영 금지. 학습 누적 후 다음 단계 finishing-a-development-branch(커밋·푸시·PR)로 진행." ;;
  *finishing-a-development-branch)
    emit "Phase 3 SHIP: model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하라. 커밋 메시지는 한국어 포맷(type 콜론 한국어 설명, WHY·주요 변경 불릿)." ;;
  *systematic-debugging)
    emit "DEBUG: model·effort는 복잡도 채점(hybrid-workflow.md 3장)으로 산출해 announce하라 — 근본원인 디버깅은 개방형 추론(base 5)이라 opus 밴드에 해당할 가능성이 높다. 수정 전 재현 테스트 먼저 작성, 근본 원인 추적. 같은 접근 3회 실패 시 중단·대안." ;;
esac
exit 0
