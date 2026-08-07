#!/usr/bin/env bash
# Superpowers 파이프라인 진입 시, Skill 호출 직후 단계별 지침을 주입한다.
# matcher:"Skill"로 모든 스킬 호출에 발동하지만, case에 없는 스킬은 clean no-op(출력 없음, exit 0).
#
# 중복 금지 원칙: 각 case는 그 단계에서만 성립하는 정보(단계 고유 산출물·다음 단계·강제 경계)만 담는다.
# 모델·effort는 사용자가 /model·/effort로 직접 설정하므로 이 파일은 라우팅을 일절 언급하지 않는다.
#
# subagent-driven-development case만 예외적으로 스킬 자체의 종료 동선을 가로챈다: SDD는 전체 브랜치
# 리뷰가 깨끗해지면 스스로 finishing-a-development-branch를 호출하며 끝나므로, 그대로 두면
# verification-before-completion이 건너뛰어진다. 이 지시는 finishing-a-development-branch case에도
# 중복 배치한다 -- SDD 시작 시점의 주입은 태스크 N개를 도는 동안 컨텍스트 밖으로 밀려나고, 순서가
# 실제로 걸리는 것은 ship을 호출하는 순간이기 때문이다(아래 계획 파일 규칙과 같은 이유).
#
# 계획 파일 규칙(writing-plans / finishing-a-development-branch 두 case에 중복 배치): 경로는
# docs/plans이고, 작업 완료 후에도 삭제하지 않는다. 생성 시점과 완료 시점 양쪽에서 말해야
# 실제로 지켜진다 -- 삭제 유혹은 완료 시점에 생기고, 그때는 writing-plans 주입이 이미 컨텍스트
# 밖으로 밀려나 있다.
#
# brainstorming case는 두지 않는다 -- 옛 case의 payload는 둘이었고 지금은 둘 다 여기 있을 이유가 없다.
# (1) 95% confidence opener: 폐기됐다. Superpowers brainstorming은 자체 인터뷰 루프(한 번에 한 질문,
# 체크리스트, 승인 게이트)를 갖고 있어 주입할 고유 정보가 없다. (2) plan 도구 override와 /clear 경계:
# 전자는 파이프라인이 실제로 writing-plans를 쓰게 되면서 무의미해졌고, 후자는 강제 규칙 자체를
# 폐기했다 -- /clear 여부는 이제 writing-plans case에서 작업 특성을 보고 사용자에게 제안한다.
# Superpowers 스킬 트리에는 /clear 언급이 0회이고, brainstorming SKILL.md는 terminal state가
# writing-plans 호출이라고 못박는다. 그 자리에 세션 단절을 강제하면 스킬 지시와 정면 충돌한다.

input=$(cat)
# jq json parse (not grep -P / sed regex, not python3): settings.json fires this via a
# non-interactive `bash script.sh` subshell, where grep resolves to BSD grep (no -P support)
# and python3 may resolve to a pyenv shim that only exists on an interactive-shell PATH --
# both fail the same way (silent no-op) in that subshell. A regex extraction (grep -P or
# sed's greedy .*"skill") is also unsafe here: tool_response can itself contain a nested
# "skill" key, and a greedy/leftmost-unaware pattern can grab that instead of the real
# tool_input.skill. jq is a documented hard dependency of this repo (see README.md, and
# rtk-rewrite.sh's identical `.tool_input.*` pattern) and resolves via the default system
# PATH with no shell-rc dependency.
skill=$(printf '%s' "$input" | jq -r '.tool_input.skill // empty' 2>/dev/null)

emit() {
  # $1: additionalContext 텍스트. 내부에 큰따옴표(")와 백슬래시(\) 사용 금지 -- JSON이 깨진다.
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}' "$1"
}

case "$skill" in
  *writing-plans)
    emit "PLAN 단계: 계획 파일은 docs/plans/YYYY-MM-DD-<feature>.md에 Write하라(docs/superpowers/plans가 아니다 — 거기에는 스펙만 산다). 본문 산문은 반드시 한국어로 작성한다(코드·식별자·파일경로·frontmatter 키·enum 값은 영문 유지). 계획 파일은 영구 보존물이다 — 작업이 끝나도 절대 삭제하지 말 것. 계획 파일 Write 후 이 세션에서 직접 코드를 쓰지 말 것 — 구현은 subagent-driven-development가 신선한 서브에이전트로 한다. 실행을 이 세션에서 바로 시작할지 /clear 후 새 세션에서 시작할지는 작업 특성을 보고 한쪽을 권하고 근거를 한 줄로 밝힌 뒤 사용자 결정을 받아라. /clear를 권하는 쪽: 태스크가 많거나(대략 5개 이상) 계획 과정에서 폐기된 선택지·중간 검색 결과가 많이 쌓인 경우 — SDD 코디네이터가 그것을 전부 물려받는다. 이어가길 권하는 쪽: 계획이 작고 컨텍스트가 얇은 경우." ;;
  *subagent-driven-development)
    emit "BUILD 단계(SDD): 태스크마다 구현 서브에이전트 → 태스크 리뷰(spec 준수 + 코드 품질), 마지막에 전체 브랜치 리뷰. 종료 단계 가로채기 — 전체 브랜치 리뷰가 깨끗해져도 finishing-a-development-branch로 바로 가지 말 것. 반드시 verification-before-completion을 먼저 거친 뒤 finishing-a-development-branch로 가라." ;;
  *test-driven-development)
    emit "BUILD(TDD): RED→GREEN→REFACTOR, 트리비얼 면제." ;;
  *requesting-code-review)
    emit "CODE REVIEW: 리뷰·수정 완료 후 다음 단계 verification-before-completion으로 진행. 계획 실행 중이라면 SDD가 이미 내부에서 같은 리뷰어를 dispatch하므로 별도 단계로 중복 호출하지 말 것." ;;
  *verification-before-completion)
    emit "VERIFY: uv run ty check·ruff check --fix·ruff format·pytest -v를 실제 실행하고 그 출력으로 확인한 뒤에만 완료를 선언하라(증거 우선). 통과 후 다음 단계 finishing-a-development-branch(커밋·푸시·PR)로 진행." ;;
  *finishing-a-development-branch)
    emit "SHIP: verification-before-completion을 아직 거치지 않았다면 먼저 수행하라 — 여기가 그것을 건너뛰기 가장 쉬운 지점이다. 커밋 메시지는 한국어 포맷(type 콜론 한국어 설명, WHY·주요 변경 불릿). docs/plans/의 계획 파일은 작업이 끝나도 삭제하지 말 것 — 영구 보존물이며, 정리 대상으로 오해하지 말 것." ;;
  *systematic-debugging)
    emit "DEBUG: 수정 전 재현 테스트 먼저 작성, 근본 원인 추적. 같은 접근 3회 실패 시 중단·대안." ;;
esac
exit 0
