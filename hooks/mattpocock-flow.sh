#!/usr/bin/env bash
# Matt Pocock 플로우 스킬을 슬래시로 호출할 때만 체인 규칙을 주입한다.
#
# 배경: 해당 스킬 18개는 frontmatter에 disable-model-invocation: true를 달고 있어
# 모델의 스킬 목록에서 빠진다. 그래서 두 가지가 터진다.
#   - 존재를 모르니 설치돼 있는 스킬을 "없다"고 답한다 (anthropics/claude-code#82237)
#   - 다음 단계를 호출할 수 없으니 그 산출물을 직접 만들어버린다 (anthropics/claude-code#82299)
# Matt은 플래그를 뺄 생각이 없고(mattpocock/skills#693) 근본 수정은 하네스 몫이라
# 그때까지 이 주입으로 막는다. 플러그인 파일은 건드리지 않으므로 업데이트에 죽지 않는다.
set -uo pipefail

input=$(cat)

# 플로우에 속한 슬래시 명령. code-review와 handoff는 동명의 내장·개인 스킬과 겹쳐 제외한다.
FLOW='grill-with-docs|grill-me|grilling|to-spec|to-tickets|implement|triage|wayfinder|ask-matt|improve-codebase-architecture|diagnosing-bugs|prototype|tdd|setup-matt-pocock-skills'

matched=$(printf '%s' "$input" | jq -r --arg flow "$FLOW" \
  '(.prompt // "") | test("(^|[^A-Za-z0-9_/-])/(mattpocock-skills:)?(" + $flow + ")([^A-Za-z0-9_-]|$)")' 2>/dev/null) || exit 0
[ "$matched" = "true" ] || exit 0

# 세션당 1회만 주입한다.
session=$(printf '%s' "$input" | jq -r '.session_id // "unknown"' 2>/dev/null)
marker="${TMPDIR:-/tmp}/claude-mp-flow-${session}"
[ -e "$marker" ] && exit 0
: > "$marker"

read -r -d '' CTX <<'EOF'
Matt Pocock 플로우 스킬을 호출했다.

아래 스킬은 disable-model-invocation: true라서 이 세션의 스킬 목록에 뜨지 않는다. 설치되어 있고 슬래시로만 열린다. 목록에 없다는 이유로 "설치되지 않았다"거나 "없다"고 답하지 마라.
grill-with-docs, grill-me, to-spec, to-tickets, implement, triage, wayfinder, ask-matt, improve-codebase-architecture, handoff, teach, to-questionnaire, wait-what, setup-matt-pocock-skills

정지 규칙: 한 단계가 끝나면 다음 단계의 산출물을 직접 만들지 마라. 스펙을 대신 쓰지 말고, 티켓을 대신 쪼개지 말고, 서브에이전트나 다른 도구로 같은 일을 우회하지도 마라. 다음에 사용자가 칠 슬래시 명령을 정확한 이름으로 알리고 거기서 멈춘다. 사용자가 명시적으로 직접 하라고 지시하면 그때 따른다.

메인 플로우: /grill-with-docs 로 아이디어를 벼린다. 설계 질문이 실행 가능한 답을 요구하면 /handoff 로 빠져 /prototype 을 거쳐 돌아온다. 여러 세션에 걸칠 일이면 /to-spec 다음 /to-tickets, 티켓마다 /implement 를 돌리고 사이사이 /clear 한다. 한 세션에 끝날 일이면 곧장 /implement 로 간다. /implement 는 내부에서 /tdd 를 돌리고 /code-review 로 닫는다.
온램프: /triage(밖에서 들어온 이슈), /diagnosing-bugs(고장난 것), /wayfinder(한 세션에 안 들어가는 큰 일)는 /to-spec 에서 메인 플로우에 합류한다.
컨텍스트 위생: /to-tickets 전까지는 한 컨텍스트를 유지하고 compact 나 clear 를 하지 않는다.
티켓 앵커: /to-tickets 로 티켓을 쓸 때, 각 티켓에 그 티켓이 건드릴 기존 심볼(함수, 클래스, 모듈) 이름을 `**Symbols:**` 한 줄로 남긴다. 파일 경로와 코드 스니펫은 to-tickets 규정대로 계속 쓰지 않는다. 심볼 이름은 낡아도 조회가 빈 결과를 줄 뿐 틀린 곳을 가리키지 않으므로 그 규정에 걸리지 않는다. 새로 만들 코드뿐이라 앵커로 쓸 기존 심볼이 없으면 그 줄을 생략한다. /implement 는 첫 턴에 그 이름들을 codegraph_explore 에 그대로 넘기고, 인덱스가 없는 저장소라면 검색 시작점으로 쓴다.
EOF

jq -nc --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit",additionalContext:$ctx}}'
