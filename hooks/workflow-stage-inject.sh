#!/usr/bin/env bash
# hybrid-workflow.md 7단계 파이프라인 진입 시, Skill 호출 직후 단계별 지침을 주입한다.
# matcher:"Skill"로 모든 스킬 호출에 발동하지만, case에 없는 스킬은 clean no-op(출력 없음, exit 0).
# 모델·effort 전환은 메인 에이전트가 세션 중 스스로 못 하므로,
# 주입 내용은 "announce + 사용자에게 전환 안내"이며 강제가 아니라 강한 넛지다.
#
# salience 보존: 원래 목표인 brainstorming opener만 full 문단으로 두고,
# 자주 호출되는 나머지 단계는 terse 1줄로 유지한다(additionalContext 습관화 → opener 희석 방지).

input=$(cat)
skill=$(printf '%s' "$input" | grep -oP '"skill"\s*:\s*"\K[^"]*' | head -1)

emit() {
  # $1: additionalContext 텍스트. 내부에 큰따옴표(") 사용 금지 — JSON이 깨진다.
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$1"
}

case "$skill" in
  *brainstorming)
    emit "BRAINSTORMING STARTED — MANDATORY FIRST TURN: rules/hybrid-workflow.md의 95퍼센트 confidence opener 규칙에 따라, 일반적인 무엇을 만들까요 식 질문 대신 반드시 다음 opener로 첫 turn을 시작하라 → 지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95퍼센트 확신이 생길 때까지 질문을 던지겠습니다, 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다. 이후 한 번에 한 질문 원칙으로 95퍼센트 확신까지 반복하고, 그 미만에서 설계 단계로 넘어가지 말 것. 제품성 작업이면 evidence·specificity·counterfactual·attachment·durability 5렌즈로 질문을 도출하라. 브레인스토밍 종료 시 superpowers가 writing-plans 호출을 안내해도 따르지 말고 /clear 후 /ce-plan으로 진행하라(이 파이프라인은 writing-plans 미사용)." ;;
  *ce-plan)
    emit "Phase 2 PLAN: Opus·xhigh 권장(디폴트와 동일, 전환 불필요). 병렬 리서치+Serena 패턴 수집, docs/solutions/ 파일 3개 이상이면 ce-learnings-researcher 조회. docs/plans/ 초안 → ExitPlanMode(plannotator) → /clear." ;;
  *test-driven-development)
    emit "Phase 2-prime BUILD(TDD): Sonnet·high 권장 — 현재 Opus면 /model sonnet·/effort high 전환 안내(강제 아님). RED→GREEN→REFACTOR, 트리비얼 면제." ;;
  *ce-work)
    emit "Phase 2-prime BUILD(ce-work): Sonnet·high 권장 — 현재 Opus면 /model sonnet·/effort high 전환 안내(강제 아님). 확정 plan 실행, Serena 심볼 편집 우선. 완료(구현+테스트) 후 인라인 종료 금지 — hybrid-workflow Phase 2-prime step3에 따라 반드시 다음 단계 /ce-code-review를 사용자에게 안내하라(ce-work 내부 Tier1 review와 별개로 항상 수행)." ;;
  *ce-code-review)
    emit "Phase 2-prime REVIEW: 세션 모델 전환 금지(세션 Sonnet 유지 — 세션 중 전환은 캐시 재로딩 비용 큼). 6+ 리뷰어 subagent 팬아웃, 중요 변경만 리뷰어 Opus 권장(강제 아님). 리뷰·수정 완료 후 다음 단계 verification-before-completion으로 진행." ;;
  *verification-before-completion)
    emit "Phase 3 VERIFY: Sonnet·high 권장. uv run ty check·ruff check --fix·ruff format·pytest -v 실제 실행 후 출력으로 확인하고 완료 선언(증거 우선). 검증 통과 후 다음 단계 ce-compound(mode:headless)로 진행." ;;
  *ce-compound)
    emit "Phase 3 LEARN: Sonnet·high 권장. mode:headless, docs/solutions/만 생성(콘텐츠 한국어, frontmatter 키·enum 영문). Tier 0/1 자동 반영 금지. 학습 누적 후 다음 단계 finishing-a-development-branch(커밋·푸시·PR)로 진행." ;;
  *finishing-a-development-branch)
    emit "Phase 3 SHIP: Sonnet·high 권장. 커밋 메시지는 한국어 포맷(type 콜론 한국어 설명, WHY·주요 변경 불릿)." ;;
  *systematic-debugging)
    emit "DEBUG: Opus·xhigh 권장(디폴트와 동일). 수정 전 재현 테스트 먼저 작성, 근본 원인 추적. 같은 접근 3회 실패 시 중단·대안." ;;
esac
exit 0
