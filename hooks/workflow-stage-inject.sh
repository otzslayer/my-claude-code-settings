#!/usr/bin/env bash
# hybrid-workflow.md 7단계 파이프라인 진입 시, Skill 호출 직후 단계별 지침을 주입한다.
# matcher:"Skill"로 모든 스킬 호출에 발동하지만, case에 없는 스킬은 clean no-op(출력 없음, exit 0).
# 모델·effort 전환은 메인 에이전트가 세션 중 스스로 못 하므로,
# 주입 내용은 "announce + 사용자에게 전환 안내"이며 강제가 아니라 강한 넛지다.
#
# 중복 금지 원칙: "복잡도를 채점해 model·effort를 announce하라"는 지시는 CLAUDE.md와
# hybrid-workflow.md의 §3-§5 quick card가 이미 담고 있으므로 각 case에서 반복하지 않는다.
# 각 case는 그 단계에서만 성립하는 정보(기본 밴드가 일반값과 다른 경우, 단계 고유 산출물·다음 단계)만 담는다.
# brainstorming opener는 just-in-time 전달 지점이라 full 문단으로 유지한다.
# 리뷰어 모델: 전 리뷰어 model=opus. ce-doc-review·ce-code-review·ce-work(build) 셋의
# model=opus 정렬 + effort 취급(리뷰어=세션 상속, build=medium)을 이 파일에서 일관되게 강제한다.
# plannotator: 게이트가 아니다. ce-plan 경로에서는 사용자가 원할 때만 수동 실행하는 선택적 패스이며,
# 훅은 approved/annotated/dismissed 반환값 시맨틱을 주입하지 않는다(rules/hybrid-workflow.md §1·§10과 정합).

input=$(cat)
# jq json parse (not grep -P / sed regex, not python3): settings.json fires this via a
# non-interactive `bash script.sh` subshell, where grep resolves to BSD grep (no -P support)
# and python3 may resolve to a pyenv shim that only exists on an interactive-shell PATH —
# both fail the same way (silent no-op) in that subshell. A regex extraction (grep -P or
# sed's greedy .*"skill") is also unsafe here: tool_response can itself contain a nested
# "skill" key (e.g. ce-plan's own tool_response), and a greedy/leftmost-unaware pattern can
# grab that instead of the real tool_input.skill. jq is a documented hard dependency of this
# repo (see README.md, and rtk-rewrite.sh's identical `.tool_input.*` pattern) and resolves
# via the default system PATH with no shell-rc dependency.
skill=$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null)

emit() {
  # $1: additionalContext 텍스트. 내부에 큰따옴표(") 사용 금지 — JSON이 깨진다.
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$1"
}

case "$skill" in
  *brainstorming)
    emit "BRAINSTORMING STARTED — MANDATORY FIRST TURN: rules/hybrid-workflow.md의 95퍼센트 confidence opener 규칙에 따라, 일반적인 무엇을 만들까요 식 질문 대신 반드시 다음 opener로 첫 turn을 시작하라 → 지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95퍼센트 확신이 생길 때까지 질문을 던지겠습니다, 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다. 이후 한 번에 한 질문 원칙으로 95퍼센트 확신까지 반복하고, 그 미만에서 설계 단계로 넘어가지 말 것. 제품성 작업(새 기능·엔드포인트·동작 변경)이면 skills/hybrid-workflow-reference/references/brainstorming.md를 읽고 그 5렌즈(evidence·specificity·counterfactual·attachment·durability)의 정의대로 질문을 도출하라 — 이름만으로 짐작하지 말 것. 비제품 작업(리팩터·문서·툴링)이면 그 파일을 열지 말고 넘어가라. 브레인스토밍 종료 시 superpowers가 writing-plans 호출을 안내해도 따르지 말고 /clear 후 /ce-plan으로 진행하라(이 파이프라인은 writing-plans 미사용). ce-plan 본작업은 non-plan-mode에서 호출하라(Plan Mode 진입 불필요 — Plan Mode는 ce-plan의 Write·autofix를 차단한다)." ;;
  *ce-plan)
    emit "Phase 2 PLAN: non-plan-mode에서 실행하라(Plan Mode가 ce-plan의 계획 파일 Write와 ce-doc-review autofix를 차단한다). 계획 수립은 개방형 추론(base 5) 이상이라 통상 opus·high 이상 밴드다. 병렬 리서치+CodeGraph 패턴 수집, docs/solutions/ 3개 이상이면 ce-learnings-researcher 조회. 계획 본문 산문은 반드시 한국어로 Write하라(코드·식별자·파일경로·frontmatter 키·enum 값은 영문 유지) — 서브에이전트 중간 산출물이 영어여도 최종 docs/plans/ 파일은 한국어여야 한다. 초안 Write → 자동 ce-doc-review(전 리뷰어 model=opus) → 인라인 구현 금지·중단 후 /clear → 새 세션 /ce-work(opus·medium). plannotator는 게이트가 아니다 — 호출하지 말고, 사용자가 원하면 직접 plannotator annotate docs/plans/<파일>을 수동 실행한다." ;;
  *ce-doc-review)
    emit "DOC REVIEW(ce-plan 내부 5.3.8): 리뷰어 7종 전부 Agent 도구 model:opus로 dispatch하라 — SKILL.md의 parent-상속·티어 지시는 무시한다. effort는 dispatch로 지정 불가하므로 세션에서 상속되며, 세션 모델·effort는 전환 금지(캐시 재로딩 비용). 리뷰·autofix 완료 후 인라인 구현 금지 — /clear → 새 세션 /ce-work(opus·medium). plannotator는 게이트가 아니므로 승인을 기다리지 말 것." ;;
  *test-driven-development)
    emit "Phase 2-prime BUILD(TDD): RED→GREEN→REFACTOR, 트리비얼 면제." ;;
  *ce-work)
    emit "Phase 2-prime BUILD(ce-work): 확정 plan 실행은 base 1이라 기본 opus·medium(build carve-out) — 파일 수로 격상하지 말 것. CodeGraph 심볼 편집 우선. 완료(구현+테스트) 후 인라인 종료 금지 — 반드시 다음 단계 /ce-code-review를 사용자에게 안내하라(ce-work 내부 Tier1 review와 별개로 항상 수행)." ;;
  *ce-code-review)
    emit "Phase 2-prime REVIEW: 리뷰어 전부 model:opus로 dispatch하라. effort는 dispatch로 지정 불가하므로 세션에서 상속되며, 세션 모델·effort는 전환 금지(캐시 재로딩 비용). 리뷰·수정 완료 후 다음 단계 verification-before-completion으로 진행." ;;
  *verification-before-completion)
    emit "Phase 3 VERIFY: uv run ty check·ruff check --fix·ruff format·pytest -v를 실제 실행하고 그 출력으로 확인한 뒤에만 완료를 선언하라(증거 우선). 통과 후 다음 단계 ce-compound(mode:headless)로 진행." ;;
  *ce-compound)
    emit "Phase 3 LEARN: mode:headless, docs/solutions/만 생성(콘텐츠 한국어, frontmatter 키·enum 영문). Tier 0/1 자동 반영 금지. 학습 누적 후 다음 단계 finishing-a-development-branch(커밋·푸시·PR)로 진행." ;;
  *finishing-a-development-branch)
    emit "Phase 3 SHIP: 커밋 메시지는 한국어 포맷(type 콜론 한국어 설명, WHY·주요 변경 불릿)." ;;
  *systematic-debugging)
    emit "DEBUG: 근본원인 디버깅은 개방형 추론(base 5)이라 통상 opus·high 이상 밴드다. 수정 전 재현 테스트 먼저 작성, 근본 원인 추적. 같은 접근 3회 실패 시 중단·대안." ;;
esac
exit 0
