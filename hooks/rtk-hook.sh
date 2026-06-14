#!/usr/bin/env bash
# RTK PreToolUse hook — `uv run <tool>` 명령을 rtk 네이티브 압축으로 라우팅한다.
#
# 동작:
#   uv run pytest|ruff|mypy ...  →  uv run rtk <tool> ...
#   venv 안에서 rtk가 도구를 직접 실행하며 출력을 압축한다. (`rtk pipe`가 아니라
#   rtk 명령 래핑 방식 — rtk 0.36.0에는 `rtk pipe` 서브커맨드가 없다.)
#
# 역할 분리:
#   - `uv run` 프리픽스는 `rtk rewrite`(rtk-rewrite.sh)가 인식하지 못하므로
#     이 훅이 담당한다.
#   - 그 외 모든 명령(git/grep/find/ls 등)은 rtk-rewrite.sh가 처리하므로
#     여기서는 손대지 않고 exit 0 한다 (역할 중복·이중 리라이트 방지).
#   - `ty`는 rtk가 아직 지원하지 않아 변환하지 않는다 (그대로 통과).
#
# 매칭은 bash `case` glob을 쓴다. (이전 버전의 `grep -P`는 훅이 spawn하는
# 비인터랙티브 bash에서 /usr/bin/grep(BSD grep)이 잡혀 `-P`가 깨졌다.)

INPUT=$(cat)
CMD=$(printf '%s' "$INPUT" | python3 -c "
import json, sys
d = json.load(sys.stdin)
print(d.get('tool_input', d).get('command', ''))
" 2>/dev/null || echo "")

[ -z "$CMD" ] && exit 0

# 이미 rtk를 거친 명령은 다시 감싸지 않는다 (이중 래핑 방지).
case "$CMD" in
  *"uv run rtk "*) exit 0 ;;
esac

# uv run <tool> ... → uv run rtk <tool> ...  (tool ∈ pytest|ruff|mypy)
new=""
case "$CMD" in
  "uv run pytest" | "uv run pytest "*) new="uv run rtk pytest${CMD#uv run pytest}" ;;
  "uv run ruff" | "uv run ruff "*) new="uv run rtk ruff${CMD#uv run ruff}" ;;
  "uv run mypy" | "uv run mypy "*) new="uv run rtk mypy${CMD#uv run mypy}" ;;
esac

[ -z "$new" ] && exit 0

printf '%s' "$new" | python3 -c "
import json, sys
cmd = sys.stdin.read()
print(json.dumps({
    'hookSpecificOutput': {
        'hookEventName': 'PreToolUse',
        'permissionDecisionReason': 'RTK uv-run wrap',
        'updatedInput': {'command': cmd}
    }
}))
"
