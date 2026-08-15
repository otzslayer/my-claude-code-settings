#!/usr/bin/env bash
# .py 편집 시 python-coding-style 스킬을 세션당 한 번만 안내한다.
#
# 배경: 이전에는 인라인 jq가 "if not already done this turn"이라는 문구만 붙였다.
# 문구에는 강제력이 없어서 .py를 건드리는 턴마다 스킬이 다시 실려 왔고, 편집 턴이
# 수십 번인 /implement 단계에서만 이 비용이 붙었다. 마커 파일로 실제로 한 번만 낸다.
set -uo pipefail

input=$(cat)

path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null) || exit 0
case "$path" in
*.py) ;;
*) exit 0 ;;
esac

session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
marker="${TMPDIR:-/tmp}/claude-py-style-${session}"
[ -e "$marker" ] && exit 0
: >"$marker"

read -r -d '' CTX <<'EOF'
Python (.py) 파일 편집을 감지했다. Skill(skill="python-coding-style")을 호출해 Ruff 설정, 불변성, 네이밍, 타입 힌트, 파일과 함수 크기 한도를 적용하라.

이 안내는 세션당 한 번만 나온다. 이후 .py 편집에도 같은 규칙이 계속 적용되므로 스킬을 다시 호출하지 마라.
EOF

jq -nc --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$ctx}}'
