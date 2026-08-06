#!/usr/bin/env bash
#
# settings.json의 머신 로컬 블록을 커밋 오브젝트에서만 제거하는 git clean/smudge 필터.
#
# 왜 필요한가:
#   git의 최소 추적 단위는 파일이라 "파일 내부 특정 블록만 추적 제외"가 없다.
#   grrr 알림 훅(Stop/Notification/UserPromptSubmit)은 이 머신에만 설치된 CLI에
#   의존하므로 커밋에 들어가면 안 되지만, Claude Code에는 user 스코프 local
#   오버레이가 없다 -- localSettings는 항상 <프로젝트 루트>/.claude/settings.local.json
#   이라 cwd가 ~/.claude인 세션에서만 로드된다. 즉 이 훅들은 전역으로 울리려면
#   ~/.claude/settings.json 안에 물리적으로 있어야 한다.
#
#   그래서 파일을 나누는 대신 커밋 경로에서만 걷어낸다:
#     clean  (worktree -> index) : LOCAL_KEYS에 해당하는 훅 이벤트를 제거
#     smudge (index -> worktree) : FRAGMENT의 내용을 다시 병합
#
#   FRAGMENT가 복원 원본이다. 이 파일이 없으면 checkout/stash 후 훅이 사라지므로
#   .gitignore 대상이면서도 삭제하면 안 된다.
#
# 등록: scripts/install.sh가 git config filter.claude-local.{clean,smudge}에 건다.
#
# 주의 -- required=true의 범위: 이 설정은 .git/config에 살아 clone을 따라가지 않는다.
#   .gitattributes만 있고 드라이버가 정의되지 않은 clone에서 git은 경고 없이 원본을
#   그대로 통과시킨다(실측 확인). 즉 required=true는 "등록은 됐는데 스크립트가
#   깨진" 경우(jq 없음, 파일 삭제)를 잡아줄 뿐, 미등록 clone은 보호하지 못한다.
#   실질 안전장치는 clone 후 install.sh 재실행이다.

set -euo pipefail

FRAGMENT="${CLAUDE_LOCAL_SETTINGS:-$HOME/.claude/local-hooks.json}"

# 커밋에서 제외할 최상위 훅 이벤트. FRAGMENT의 .hooks 키와 일치해야 한다.
LOCAL_KEYS='["Stop","Notification","UserPromptSubmit"]'

case "${1:-}" in
    clean)
        # jq가 실패하면(비정상 JSON) 그대로 실패시킨다 -- 로컬 블록이 통째로
        # 커밋에 새는 것보다 커밋이 멈추는 편이 안전하다.
        jq --argjson keys "$LOCAL_KEYS" \
           'if has("hooks") then .hooks |= delpaths([$keys[] | [.]]) else . end'
        ;;
    smudge)
        if [[ -f "$FRAGMENT" ]]; then
            # jq의 * 는 객체 재귀 병합. clean이 지운 키라 충돌 없이 되살아난다.
            jq -s '.[0] * .[1]' - "$FRAGMENT"
        else
            # 프래그먼트가 없는 머신(다른 clone 등)에서는 원본 그대로 통과시킨다.
            cat
        fi
        ;;
    *)
        echo "usage: $(basename "$0") clean|smudge" >&2
        exit 64
        ;;
esac
