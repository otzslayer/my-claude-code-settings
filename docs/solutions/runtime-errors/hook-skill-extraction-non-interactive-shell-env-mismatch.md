---
title: 훅 스크립트의 skill 추출 로직이 비대화형 서브셸 환경 불일치로 세 번 연쇄 실패한 사례
date: 2026-07-04
category: docs/solutions/runtime-errors
module: hooks/workflow-stage-inject.sh
problem_type: runtime_error
component: development_workflow
symptoms:
  - "훅이 정상 종료(exit 0)되지만 어떤 skill 호출에도 additionalContext를 주입하지 않음 — 매 실행마다 조용히 no-op됨"
  - "skill 변수가 항상 빈 문자열이라 case문의 모든 분기가 매칭되지 않음"
  - "stdin JSON의 tool_response 필드가 중첩된 skill 키를 포함할 때(예를 들어 ce-plan의 tool_response) 엉뚱한 skill의 guidance가 주입됨"
  - "인터랙티브 셸에서 which <tool>로 정상 동작을 확인한 도구(예: python3)가 실제 훅의 비대화형 서브셸에서는 resolve되지 않거나 다른 바이너리로 resolve될 수 있음"
  - "모든 실패 단계에서 에러나 stderr 출력이 전혀 없어 다음 조사 전까지 발견되지 않음"
root_cause: config_error
resolution_type: code_fix
severity: high
related_components:
  - settings.json
  - hooks/rtk-rewrite.sh
tags: [non-interactive-shell, subshell-path-resolution, pyenv-shim, bsd-vs-gnu-grep, json-parsing-safety, jq, claude-code-hooks, environment-verification]
---

# 훅 스크립트의 skill 추출 로직이 비대화형 서브셸 환경 불일치로 세 번 연쇄 실패한 사례

## Problem

`hooks/workflow-stage-inject.sh`는 훅 stdin JSON 페이로드에서 호출된 skill 이름(`tool_input.skill`)을 추출해, 해당 skill의 파이프라인 단계에 맞는 `additionalContext` 문자열을 주입한다. 이 브랜치의 연속된 세 커밋에 걸쳐 이 추출 로직이 세 번 다시 작성됐다 — 매번 직전 버전의 실재하는 재현 가능한 버그를 고쳤지만, 그때마다 새로운 버그를 만들거나 드러냈다. 원인은 모든 수정이 훅의 실제 비대화형 실행 환경과 다른 환경에서 검증됐기 때문이다.

## Symptoms

- 훅이 정상 종료(exit 0)되지만 어떤 skill 호출에도 `additionalContext`를 주입하지 않음 — 매 실행마다 조용히 no-op됨
- `skill` 변수가 항상 빈 문자열이라 `case`문의 모든 분기가 매칭되지 않음
- stdin JSON의 `tool_response` 필드가 중첩된 `"skill"` 키를 포함할 때(예를 들어 보고 대상 도구가 `ce-plan`이고 그 `tool_response`가 자체적으로 `"skill"` 필드를 담고 있을 때) 엉뚱한 skill의 guidance가 주입됨
- 인터랙티브 셸에서 `which <tool>`로 정상 동작을 확인한 도구(예: `python3`)가 실제 훅의 비대화형 서브셸에서는 resolve되지 않거나 전혀 다른 바이너리로 resolve될 수 있음
- 이 사가(saga)의 모든 실패 단계에서 크래시나 stderr 출력이 전혀 없음 — 매번 "성공적으로" 실패하기 때문에 다음 조사가 있기 전까지 발견되지 않고 넘어감

## What Didn't Work

### Stage 0 — 기준선(`grep -oP`, 이 브랜치 이전)

```bash
skill=$(printf '%s' "$input" | grep -oP '"skill"\s*:\s*"\K[^"]*' | head -1)
```

JSON 키 뒤의 따옴표로 감싸인 값을 추출하는 방법으로 `grep -P`(PCRE 모드)는 자연스럽고 간결해 보였고, `\K`는 매칭된 접두사를 출력에서 깔끔하게 제거하는 방법이다. 인터랙티브 터미널에서 스크립트를 직접 실행해 테스트했을 때는 거의 확실히 동작했을 것이다 — 그 환경에서는 `grep`이 (Homebrew의 `ggrep`이나 GNU coreutils를 우선하는 `PATH` 설정을 통해) GNU grep으로 resolve됐을 가능성이 높기 때문이다.

**왜 실패했는가**: `settings.json`은 이 훅을 비대화형 `bash script.sh` 서브셸을 통해 발동한다 — 인터랙티브 셸의 `PATH` 커스터마이징을 전혀 상속받지 않는 최소한의 환경이다. 그 서브셸에서 `grep`은 BSD grep(macOS 기본 `/usr/bin/grep`)으로 resolve되는데, 이 버전은 `-P` 플래그를 아예 지원하지 않는다. BSD grep은 에러를 내거나 패턴을 지원하지 않는 것으로 처리하지만, 결정적으로 이를 감싸는 `$(...)` 캡처가 어떤 에러 출력도 삼켜버리고, 이 스크립트에는 주변에 에러 처리가 전혀 없다 — 그 결과 패턴은 매 호출마다 조용히 아무것도 매칭하지 못한다. `skill`은 항상 비어 있고, 모든 `case` 분기가 매칭에 실패하며, 훅은 눈에 보이는 증상 없이 영원히 아무것도 주입하지 않는다. "한 셸에서 검증했지만, 같은 명령 이름을 다른 바이너리로 resolve하는 다른 셸에 배포됨"이라는 이 버그 클래스는 아래 Stage 2와 이어지는 공통 맥락이다.

### Stage 1 — 커밋 `6959078`(`sed -nE`, 더 큰 무관한 리팩터 커밋 안에 함께 포함되어 랜딩)

```bash
# sed -nE (not grep -P): settings.json fires this via a non-interactive `bash script.sh`
# subshell, where grep resolves to BSD grep (no -P support) — PCRE would silently no-op every case.
skill=$(printf '%s' "$input" | sed -nE 's/.*"skill"[[:space:]]*:[[:space:]]*"([^"]*)".*/\1/p' | head -1)
```

이 수정은 Stage 0의 실제 근본 원인을 정확히 겨냥했다: BSD `sed`는 (`grep`이 `-P`를 지원하지 않는 것과 달리) `-E`(확장 정규식)를 네이티브로 지원하므로, PCRE를 강제로 지원시키려 하는 대신 다른 도구로 바꾼 것은 옳은 직감이었다. 이 수정은 실제로 동작했고 "항상 비어 있음" 증상을 고쳤다 — 단순한 입력에 대해서는 `skill`이 JSON에서 올바르게 채워졌다.

**왜 실패했는가**: 도구 resolve 문제는 고쳤지만, 도구 선택과는 무관한 새롭고 독립적인 버그 — greedy 정규식 추출의 위험성 — 를 만들어냈다. 패턴 앞뒤의 `.*`는 greedy이고, `sed`는 (JSON 구조나 키 중첩에 대한 이해가 전혀 없는 대부분의 정규식 엔진처럼) raw stdin 문자열 *전체*에 대해 매칭한다. 이 훅의 전체 stdin 페이로드에는 `tool_input.skill`뿐 아니라 `tool_response` 필드도 포함되어 있고, `tool_response` 자체가 중첩된 `"skill"` 키를 담을 수 있다(구체적으로: 보고 대상 도구가 `ce-plan`이고 그 `tool_response` 페이로드가 자체적으로 `"skill"` 필드를 임베드하는 경우). raw JSON 텍스트에 대한 greedy하고 leftmost-unaware한 정규식 추출은 의도한 최상위 `tool_input.skill` 값과 페이로드 어딘가의 무관한 중첩 `"skill"` 값을 구별할 방법이 없다 — 잘못된 값을 매칭해 엉뚱한 skill의 guidance를 조용히 주입할 수 있다. 이후 `ce-code-review` 과정에서 보안 리뷰어가 이를 직접 재현 테스트로 확인된 실재하는 실패 모드로 발견했다 — 이론적 우려가 아니었다.

### Stage 2 — 커밋 `85c0af7`(`python3 -c`의 `json.load`, 리뷰어 발견에 대응)

```bash
skill=$(printf '%s' "$input" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("skill", ""))
except Exception:
    pass')
```

이 수정은 Stage 1의 문제를 정확히 고쳤다: 실제 JSON 파싱은 객체 구조를 실제로 순회해 `tool_input.skill`을 구체적으로 읽으므로, 페이로드 다른 곳(예: `tool_response` 내부)의 중첩 `"skill"` 키와 더 이상 혼동될 수 없다. 정규식 대신 구조화된 파싱을 쓴다는 방향 자체는 옳았고, 실제로 동작이 검증됐다.

**왜 실패했는가**: Stage 0과 *동일한 근본 클래스*의 새 버그를 만들었다 — 잘못된 환경에서 검증한 것이다. 개발자는 평소 인터랙티브 셸에서 `which python3`를 실행해 `python3`의 존재를 확인했는데, 이는 `~/.pyenv/shims/python3`(pyenv shim)로 resolve됐다. pyenv shim은 pyenv의 셸 통합(전형적으로 `eval "$(pyenv init -)"`)이 설치하는 `PATH` 항목과 셸 함수에 의존하는 얇은 디스패처 스크립트이며, 이 셸 통합은 인터랙티브 셸 rc 파일(`.zshrc`, `.bashrc`)에 의해 로드된다. 그러나 훅은 그 인터랙티브 셸 컨텍스트에서 전혀 실행되지 않는다 — Stage 0과 정확히 동일하게, `settings.json`이 직접 발동시키는 비대화형 `bash script.sh` 서브셸에서 실행되며, 이 서브셸은 rc 파일을 절대 소싱하지 않는다. 실제 실행 환경에서 `python3`는 아예 resolve되지 않거나(`command not found`), 인터랙티브 테스트 때 사용된 것과 완전히 다른 인터프리터로 resolve될 수 있다. 이는 Stage 0과 형태적으로 동일한 버그다 — "인터랙티브 셸에서는 검증됐지만 실제 비대화형 실행 환경에서는 잘못됐거나 부재할 수 있음" — 단지 다른 도구(GNU `grep` 대신 `python3`)로 재발했을 뿐이며, 바로 이 점이 이 사례를 서로 무관한 세 개의 버그가 아니라 하나의 진짜 디버깅 사가로 만든다.

## Solution

Stage 2의 `python3` JSON 파싱을 `jq` 기반 구조화 추출로 교체한다. 동일한 필드 경로 시맨틱(`tool_input.skill`)은 유지하되, 훅의 실제 실행 환경에서 존재가 입증 가능한 의존성을 통해 resolve하도록 바꾼다.

Before (Stage 2):

```bash
skill=$(printf '%s' "$input" | python3 -c 'import json, sys
try:
    print(json.load(sys.stdin).get("tool_input", {}).get("skill", ""))
except Exception:
    pass')
```

After (Stage 3, 커밋 `9268f76`):

```bash
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
```

이 최종 수정의 검증은 인터랙티브 `which jq` 확인에 의존하지 않았다 — 개발자는 대신 추출 로직 자체를 `env -i`(상속되는 `PATH` 없음, 소싱되는 rc 파일 전혀 없음의 완전히 격리된 환경) 하에서 실행했다. 이는 인터랙티브 셸보다 훅의 실제 비대화형 실행 컨텍스트를 훨씬 가깝게 시뮬레이션한다. `env -i` 하에서도 `/usr/bin/jq`는 셸 rc 파일이나 pyenv, 어떤 인터랙티브 셸 설정에도 의존하지 않고 순수 기본 시스템 `PATH`만으로 정상 resolve됐다. 이전에 깨졌던 세 가지 케이스 모두 `env -i` 하에서 재검증됐다: 일반적인 skill 값은 정상 추출되고, `tool_response` 내부의 중첩 `"skill"` 키 케이스는 더 이상 혼동을 일으키지 않는다(`jq`의 구조화된 `.tool_input.skill` 경로는 오직 그 정확한 필드만 읽기 때문), malformed JSON은 크래시 대신 (`2>/dev/null`과 `// empty`를 통해) 빈 문자열로 우아하게 degrade된다.

## Why This Works

세 실패를 관통하는 일반 패턴은 다음과 같다: **인터랙티브 셸 검증(`which <tool>`, 혹은 터미널에서 명령을 실행해 성공을 지켜보는 것)은 비대화형 서브셸의 실행 환경에서의 정확성을 증명하지 못한다.** 인터랙티브 로그인/인터랙티브 셸은 `.zshrc`/`.bashrc`를 소싱하며, 여기서 `PATH` 항목·shim·함수(Homebrew prefix, pyenv/rbenv/nvm shim, alias 등)가 설치될 수 있다. `settings.json`이 발동시키는 순수한 `bash script.sh` 서브셸은 이런 것들을 전혀 보지 못한다. 인터랙티브에서는 한 방식으로 resolve되던 명령 이름이, 같은 스크립트 라인이 훅의 실제 서브셸 안에서 실행될 때는 다른 바이너리로 resolve되거나 아예 resolve되지 않을 수 있다 — 그리고 이 훅에는 그런 실패를 드러내는 에러 서피싱이 전혀 없으므로 실패 모드는 크래시가 아니라 침묵(빈 출력, `$(...)`가 삼켜버린 `command not found`)이다. Stage 0의 `grep -P`와 Stage 2의 `python3`는 정확히 동일한 결함 클래스의 두 독립적인 사례이며, 단지 서로 다른 두 도구에서 발생했을 뿐이다.

`jq`가 이를 피하는 이유는 단순히 "이번엔 우연히 실패하지 않은 또 다른 도구"이기 때문이 아니라, 구조적인 이유로 신뢰성 있게 resolve되기 때문이다: (1) 이미 이 저장소의 문서화된 hard dependency이며(`README.md`에 기재), 이는 기본 `PATH`에서의 존재가 가정이 아니라 명시된 계약이라는 뜻이다. (2) 이 저장소의 기존 훅(`hooks/rtk-rewrite.sh`)이 이미 동일한 `.tool_input.*` `jq` 추출 패턴을 프로덕션에서 성공적으로 사용 중이므로, 이는 최초 도입이 아니라 이미 현장에서 검증된 패턴이다. (3) 이 환경에서 `jq`는 셸 rc 파일이나 버전 매니저 shim에 전혀 의존하지 않고 순수 기본 시스템 `PATH`(`/usr/bin/jq`)로 resolve된다 — 이는 인터랙티브 `which` 확인이 아니라 훅의 실제 호출 컨텍스트와 실제로 일치하는 `env -i` 하에서 직접 확인됐다.

환경 문제와 별개로, 추출 정확성 축에서도: `jq`의 `.tool_input.skill`은 raw 페이로드 문자열에 매칭되는 텍스트 패턴이 아니라 파싱된 JSON 객체에 대한 구조화된 필드-경로 조회다. 실제 객체 계층을 순회하기 때문에, `tool_response` 내부 등 문서 어딘가에 존재하는 무관한 중첩 `"skill"` 키에 혼동되지 않는다 — 이는 Stage 2의 `python3`/`json.load` 수정이 이미 달성했던 것과 동일한 범주의 정확성이며, Stage 3은 Stage 2가 초래한 환경 resolve 문제를 고치면서도 이 정확성을 그대로 유지한다.

## Prevention

- **훅에서 실행되는 셸 로직은 인터랙티브 셸 확인이 아니라 `env -i`(또는 동등한 완전 격리) 하에서 검증한다.** `which <tool>`이나 터미널에서의 수동 실행은 *당신의* 인터랙티브 셸의 `PATH`에서 그 도구가 resolve된다는 것만 증명할 뿐, `settings.json`이 실제로 발동시키는 비대화형 서브셸과는 임의로 다를 수 있다. 훅 스크립트 안의 어떤 명령이든 신뢰하기 전에, 상속된 `PATH`나 소싱된 rc 파일 없이 resolve되는지 추출 로직 자체(또는 최소한 `env -i which <tool>`)를 실행해 확인한다.
- **저장소에 이미 hard dependency로 문서화된 도구를 즉흥적인 인터프리터보다 우선한다.** `README.md`에 hard dependency로 기재되어 있거나 형제 훅(예: `rtk-rewrite.sh`의 `.tool_input.*` `jq` 패턴)이 이미 성공적으로 사용 중인 도구는 실제 실행 환경에서의 존재가 입증 가능하다 — 이는 편한 셸에서 한 번 검증된 가정이 아니라 명시된 계약이다. 훅 안에서 `python3`, `ruby` 등 즉흥적인 인터프리터로 손을 뻗는 것은, 인터랙티브 테스트에서는 동작하더라도 정확히 같은 위험을 다시 끌어들이는 것이다.
- **다른 곳에 같은 키 이름이 중첩될 수 있는 JSON 페이로드에서 필드를 추출할 때 greedy 정규식(`grep -P`, `sed`의 `.*`)을 절대 쓰지 않는다.** 대신 실제 JSON 파싱/구조화된 필드 접근을 사용한다 — `jq`의 `.tool_input.skill` 경로 문법은 문서 다른 곳에 같은 이름의 키가 몇 개 있든 정확히 그 필드만 읽는다. 이는 앞으로 유사한 stdin-JSON 필드 추출을 하는 모든 훅에 적용된다. 권장 템플릿:

```bash
# stdin JSON을 읽어 jq의 구조화된 경로 문법으로 특정 최상위 필드를 추출한다.
# malformed 입력에서는 크래시 대신 빈 문자열로 degrade된다.
value=$(printf '%s' "$input" | jq -r '.some_top_level_field.nested_field // empty' 2>/dev/null)
```

## Related Issues

- 관련 GitHub 이슈 없음 — 저장소(`otzslayer/my-claude-code-settings`)에 이슈가 전혀 없음
- 관련 기존 `docs/solutions/` 문서 없음 — 이 저장소에서의 최초 `ce-compound` 실행
- `CLAUDE.md`, `README.md`가 `workflow-stage-inject.sh`를 파일명으로만 언급할 뿐 내부 추출 구현을 문서화하지 않으므로, 이번 수정으로 stale해지는 기존 문서는 없음
