#!/usr/bin/env bash
# SessionStart: 현재 프로젝트에 graphify 설정이 돼 있는지 확인하고, 안 돼 있으면
# Claude에게 "사용자에게 graphify 설치를 물어보라"는 지침을 주입한다.
#
# graphify 설정 = `graphify claude install`이 {PROJECT_ROOT}/.claude/settings.json에
#   등록하는 PreToolUse graphify 훅(코드 질문/수정 전에 항상 graph를 먼저 참조시킴).
#   그 훅은 graphify-out/ 경로를 참조하므로, settings.json 안의 'graphify-out'
#   문자열 존재로 설치 여부를 판정한다(권한 항목 등 단순 'graphify' 언급 오탐 회피).
# 이미 설정돼 있으면 clean no-op(출력 없음, exit 0).
#
# 자동 실행하지 않는다: 비개발/문서 위주 프로젝트엔 불필요할 수 있으므로,
#   설치 여부는 Claude가 사용자에게 물어본 뒤 동의할 때만 진행한다.
#   사용자가 거절하면 Claude가 {PROJECT_ROOT}/.claude/.graphify-skip 마커를 남기고,
#   이후 세션에서는 그 마커를 보고 침묵한다(같은 프로젝트에서 반복 질문 방지).
#
# 주의: additionalContext 텍스트 안에 큰따옴표(")·% 를 쓰지 않는다(JSON 깨짐 방지).

input=$(cat)

# 자동 compaction(mid-work)에서는 발동하지 않는다 — 진입(startup/resume/clear)에서만.
src=$(printf '%s' "$input" | grep -oP '"source"\s*:\s*"\K[^"]*' | head -1)
[ "$src" = "compact" ] && exit 0

proj="${CLAUDE_PROJECT_DIR:-$PWD}"
settings="$proj/.claude/settings.json"
skip="$proj/.claude/.graphify-skip"

# 사용자가 이전에 '설정 안 함'을 택해 스킵 마커를 남겼으면 침묵(이 프로젝트에선 다시 묻지 않음).
[ -f "$skip" ] && exit 0

# 이미 graphify 훅이 설치돼 있으면 침묵.
if [ -f "$settings" ] && grep -q 'graphify-out' "$settings" 2>/dev/null; then
  exit 0
fi

printf '%s' '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"이 프로젝트에는 graphify 설정이 없습니다(.claude/settings.json에 graphify 훅 미등록). graphify는 Claude가 코드 질문에 답하거나 코드를 수정하기 전에 항상 지식 그래프를 먼저 참조하도록 만드는 도구입니다. 이번 세션의 첫 행동으로, 사용자의 다른 요청을 처리하기 전에, AskUserQuestion으로 이 프로젝트에 graphify를 설정할지 먼저 물어보세요. 비개발/문서 위주 프로젝트라면 필요 없을 수 있다고 함께 안내하세요. 사용자가 동의하면 프로젝트 루트에서 graphify claude install 명령을 실행해 설정하세요. 사용자가 거절하면 설치하지 말고, 프로젝트의 .claude/ 디렉토리에 .graphify-skip 빈 파일을 만들어(.claude 디렉토리가 없으면 먼저 생성) 이후 세션에서 다시 묻지 않도록 하세요. 이 graphify 설정 질문을 먼저 끝낸 뒤에 사용자의 원래 요청을 처리하세요. 사용자가 다른 작업을 먼저 해달라고 명시적으로 요구할 때만 순서를 양보하세요."}}'
