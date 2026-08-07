# capturing-learnings — 커스텀 회고 스킬 설계

- **날짜**: 2026-08-07
- **상태**: 승인됨
- **배경 TODO**: `TODO.md` "커스텀 회고 스킬을 만든다"
- **선행 작업**: `docs/superpowers/specs/2026-08-07-superpowers-only-harness-design.md` (compound-engineering 비활성화)

## 1. 문제

Superpowers 단독 전환에서 `compound-engineering` 플러그인을 껐다(`settings.json` →
`"compound-engineering@compound-engineering-plugin": false`). 그 플러그인의 `/ce-compound`가 맡던
**학습 누적 단계**가 비어 있다. 파이프라인은 brainstorming → writing-plans →
subagent-driven-development → verification-before-completion → finishing-a-development-branch로
끝나고, 작업에서 배운 것을 남기는 자리가 없다.

`docs/solutions/`에는 문서가 3개 있다. 그 3개를 만들어 낸 `ce-compound`는 SKILL.md 802줄 +
`references/` 8개 + `scripts/` 묶음(세션 히스토리 탐색 3종, 검증 2종) + 병렬 서브에이전트 4종이었다.
**코퍼스 규모에 맞춰 대체물을 설계한다** — `ce-compound`의 야심이 아니라.

## 2. 제약

- **플러그인 캐시를 참조하지 않는다.** `plugins/cache/.../compound-engineering/<version>/`은 릴리스마다
  버전 세그먼트가 바뀌고 업그레이드 때 쓸려나간다. 게다가 플러그인이 꺼져 있다. 가져올 조각은
  새 스킬 디렉터리로 **복사(vendoring)**한다.
- **`docs/solutions/`는 git-tracked**다. `.gitignore:35-42`가 `/docs/*`를 막고
  `!/docs/solutions/`로 화이트리스트한다(`docs/plans/`는 반대로 추적 제외). 따라서 커밋이 스킬 범위에 들어온다.
- 본문 산문은 한국어. frontmatter 키·enum 값·파일 경로·디렉터리명은 영문.
- 훅의 `emit()`은 raw `printf`로 JSON을 조립한다 — 주입 문자열에 `"`·`\` 사용 금지.

## 3. 산출물

`skills/capturing-learnings/SKILL.md` — **단일 파일**. `references/`·스크립트·서브에이전트 없음.

이름은 Superpowers 명명 관례(동명사형: `brainstorming`, `writing-plans`,
`verification-before-completion`)를 따른다. 호출은 `Skill(skill="capturing-learnings")`.

## 4. 실행 흐름

```
게이트 1: 근거 확보 (3분기)
   ├ 세션 맥락 있음                       → 세션 모드
   ├ 맥락 없음 + 사용자의 조사 지시 있음  → 브랜치 증거 모드
   └ 맥락 없음 + 지시 없음                → 중단, 파일 안 씀
   ↓
게이트 2: 학습 판정 (3질문, 두 모드 공통)
   └ 탈락 → "학습 없음 + 근거 한 줄", 파일 안 씀
   ↓
트랙 결정 (bug / knowledge) → problem_type → 카테고리 디렉터리
   ↓
중복 확인 (docs/solutions 전수 나열 + 제목·태그 대조)
   └ 겹침 → 기존 문서 갱신(last_updated 추가), 새 파일 안 만듦
   ↓
문서 작성 → 근거 확인(코드 동작 주장은 트리에서 읽고 file:line 인용)
   ↓
커밋 (docs: 한국어 포맷, rules/git-workflow.md)
```

### 4.1 게이트 1 — 근거 확보

| 상황 | 모드 | 1차 증거 |
|---|---|---|
| 세션 맥락 있음 | **세션 모드** | 대화 컨텍스트. git·계획 파일은 보조 |
| 맥락 없음 + 사용자의 조사 지시 있음 | **브랜치 증거 모드** | git 커밋 본문·계획 파일 |
| 맥락 없음 + 지시 없음 (맨 호출) | **중단** | — |

**"조사 지시"의 판정**: 사용자가 스킬 호출과 함께 조사 대상을 지정한 경우 — **주제**("이런 내용에 대해
학습을 작성해줘") 또는 **범위**("이 브랜치에서 학습할 내용을 찾아 작성해줘"). 애매하면 `AskUserQuestion`으로 묻는다.

이것이 **자동 폴백이 아니라 사용자 옵트인**인 것이 핵심이다. 맥락이 없다고 조용히 품질을 낮춰 진행하면,
근거 없는 문서가 코퍼스에 들어와 검색 가치를 갉아먹는다.

중단 시 출력: 세션 맥락이 없다는 사실 + 두 갈래 안내(작업 세션에서 다시 부르거나, 조사 대상을 지정해
다시 부르거나). 파일은 쓰지 않는다.

### 4.2 브랜치 증거 모드

**근거 순서**:

1. `git log <base>..HEAD` 전체 본문 — 1차 근거
2. `git diff <base>...HEAD` — 무엇이 바뀌었나
3. `docs/plans/` 해당 계획 파일 — 폐기된 선택지, 계획과 실제의 괴리
4. `docs/superpowers/specs/` 해당 스펙 — 설계 결정의 근거
5. `TODO.md` — 범위 밖으로 남긴 것과 그 이유
6. PR 본문 (`gh pr view`, 있을 때만)
7. 사용자가 준 주제 힌트

`<base>`는 기본 `main`. 다르면 사용자에게 확인한다.

**품질 규칙 둘**:

1. **추측으로 서사를 만들지 않는다.** "What Didn't Work"(bug 트랙)는 커밋 본문·계획 파일에 실제
   기록이 있을 때만 쓴다. 없으면 그 섹션을 **통째로 생략**한다 — 빈 섹션도, 그럴듯한 재구성도 금지.
2. **출처를 본문에 박는다.** 문서 제목 바로 아래에 인용 한 줄:
   `> 이 문서는 세션 맥락 없이 브랜치 증거(커밋 본문·계획 파일)만으로 작성됐다.`
   frontmatter 필드를 늘리지 않으면서 신뢰 수준을 표시한다.

**전제와 그 한계**: 브랜치 증거 모드가 성립하는 것은 이 저장소가 `rules/git-workflow.md`로 커밋 본문에
WHY 불릿을 강제하고, `docs/plans/`·`docs/superpowers/specs/`에 설계 근거를 남기기 때문이다. 실제로
`refactor/superpowers-only-harness` 브랜치의 커밋 본문은 잘못 알았다가 고친 기록까지 담고 있다
(예: "삭제된 brainstorming case가 opener 외에 /clear 경계도 들고 나갔다는 사실을 주석에 정정한다").
**그 규율이 없는 저장소에서는 산출물이 얇아진다.** 스킬은 이 사실을 알고 있어야 하며, 근거가 빈약하면
문서를 축소하거나 게이트 2에서 탈락시킨다.

### 4.3 게이트 2 — 학습 판정

셋 다 "예"여야 문서를 쓴다. 두 모드 공통.

| 질문 | 탈락 예시 |
|---|---|
| (a) **비자명한가** | 오타, 명백한 실수, 공식 문서만 읽어도 아는 것 |
| (b) **재발하는가** | 이 저장소나 다음 프로젝트에서 다시 마주칠 종류인가. 1회성 데이터 정리는 탈락 |
| (c) **트리 밖 지식인가** | 코드·커밋·계획 파일을 읽으면 알 수 있는 것은 탈락. 값어치는 "왜 그렇게 됐는가"와 "무엇이 안 통했는가"에 있다 |

탈락 시 출력: `학습 없음 — <어느 질문에서 탈락했는지 한 줄>`. 파일은 쓰지 않는다. 이것은 **정상 종료**이며
실패가 아니다. 매 실행마다 문서를 뱉는 회고는 3개짜리 코퍼스를 한 달 만에 노이즈로 채운다.

### 4.4 중복 확인

`docs/solutions/`를 전수 나열하고 제목·`tags`·`module`을 대조한다. 문서가 3개인 트리에서 5차원
중복 점수화나 전용 서브에이전트는 과하다.

같은 문제·같은 원인·같은 해법을 다루는 문서가 있으면 **새 파일을 만들지 않고 기존 문서를 갱신**한다
(경로·frontmatter 구조 유지, `last_updated: YYYY-MM-DD` 추가, 제목은 문제 규정이 실제로 바뀐 경우에만 변경).
같은 문제를 기술한 문서 둘은 반드시 서로 어긋나기 때문이다.

## 5. frontmatter 스키마

공통:

```yaml
title: <한국어 한 줄>
date: YYYY-MM-DD
category: <디렉터리명>        # 전체 경로 아님
module: <주 대상 파일·디렉터리>
problem_type: <enum>
tags: [kebab-case, ...]
last_updated: YYYY-MM-DD      # 갱신 시에만
```

트랙별 추가 — bug: `symptoms: [...]` / knowledge: `applies_when: [...]`

**버리는 필드**: `component`, `severity`, `root_cause`, `resolution_type`, `related_components`.
3개짜리 코퍼스에서 검색·필터에 쓰인 적이 없고 enum 관리 비용만 든다. `tags`가 그 역할을 대신한다.

**`problem_type` → 디렉터리** (1:1, 복수형이라 별도 매핑 파일이 필요 없다):

| 트랙 | problem_type | 디렉터리 |
|---|---|---|
| bug | `runtime_error` | `runtime-errors/` |
| bug | `build_error` | `build-errors/` |
| bug | `test_failure` | `test-failures/` |
| knowledge | `design_pattern` | `design-patterns/` |
| knowledge | `workflow_issue` | `workflow-issues/` |
| knowledge | `convention` | `conventions/` |

기존 3개 문서가 이 enum 안에 전부 들어간다(`runtime_error`, `design_pattern`, `workflow_issue`).

**YAML 안전 규칙**: 스칼라 값에 ` #`(공백+해시, 주석으로 잘림)이나 `: `(콜론+공백, 중첩 매핑으로 오독)이
들어가면 값 전체를 따옴표로 감싼다. 배열 항목도 같다.

파일명: `<문제를-요약한-kebab-case-슬러그>.md`. 날짜 접미사를 붙이지 않는다 — `date:` 필드가 정본이다.

## 6. 문서 본문 구조

헤딩은 한국어 병기(`## 배경 (Context)`) — 기존 3개 문서가 이미 그 형태다.

- **bug 트랙**: Problem / Symptoms / What Didn't Work / Solution / Why This Works / Prevention
- **knowledge 트랙**: Context / Guidance / Why This Matters / When to Apply / Examples

두 트랙 모두 마지막에 `## Related` — 겹치는 기존 문서가 있으면 링크, 없으면 없다고 적는다.

**근거 규칙**: 코드가 어떻게 동작하는지 주장할 때(enum 값, 기본값, 한계, 의미론)는 정의하는 줄을 트리에서
읽고 `file:line`을 인용한다. 확인할 수 없는 주장은 단정하지 말고 완화하거나 출처를 밝힌다
("이번 세션의 결론에 따르면…"). 세션 요약에서 잘못된 의미가 영구 지식으로 굳는 것을 막는 값싼 방어다.
`ce-compound`는 이것을 스크립트 2개 + 검증 서브에이전트로 했지만, 여기서는 규칙 한 줄로 흡수한다.

## 7. 기존 3개 문서 정렬

- `runtime-errors/hook-skill-extraction-non-interactive-shell-env-mismatch.md`:
  `category: docs/solutions/runtime-errors` → `runtime-errors`
- 3개 모두에서 §5의 버린 필드 제거(`component`, `severity`, `root_cause`, `resolution_type`,
  `related_components`)
- **본문은 손대지 않는다**

## 8. 배선

- **`CLAUDE.md` 스킬 표**에 행 추가: `작업 완료 후 학습 기록 | capturing-learnings`.
  `rules/boundaries.md`는 `CLAUDE.md` 자동 기록을 금지하지만, **`TODO.md`가 이 행 추가를 명시적으로
  사전 승인**했다("그 스킬이 생기면 CLAUDE.md 스킬 표에 행을 하나 더하고").
- **`hooks/workflow-stage-inject.sh`**:
  - `*capturing-learnings)` case 신규 — 단계 고유 지침(게이트 순서, 한국어 본문, `docs/solutions/` 경로,
    학습 없음도 정상 종료).
  - `*finishing-a-development-branch)` case에 한 줄 추가 — 남길 학습이 있으면 ship 직후 **같은 세션에서**
    돌리라는 안내. `/clear` 뒤에는 실패 경로 증거가 사라진다는 근거 포함. **자동 실행이 아니라 안내다.**
- **`TODO.md`** 해당 항목 `- [x]`

## 9. 실패 모드

| 상황 | 동작 |
|---|---|
| 세션 맥락 없음 + 조사 지시 없음 | 중단, 파일 안 씀 |
| 학습 판정 탈락 | 근거 한 줄 출력, 파일 안 씀 (정상 종료) |
| 기존 문서와 중복 | 새 파일 대신 기존 문서 갱신 |
| 카테고리·트랙 애매 | `AskUserQuestion`으로 확인 — 추측 금지 |
| 브랜치 증거가 빈약 | 해당 섹션 생략. 전체가 빈약하면 게이트 2에서 탈락 |

## 10. 검증

스킬은 프롬프트 파일이라 단위 테스트가 없다. 검증은 셋:

1. **스키마 일치** — 기존 3개 정렬 후 `grep`으로 frontmatter 필드 집합이 §5와 맞는지 확인
2. **훅 JSON 유효성** — case 추가 후 훅에 샘플 stdin을 흘려 `jq`로 파싱되는지 확인. 주입 문자열에
   `"`·`\`가 없어야 한다
3. **도그푸딩** — 스킬이 완성되면 이 작업 자체에 대해 한 번 돌려, 게이트 2를 실제로 통과하는지 확인

## 11. 명시적 비목표

- 세션 로그(`~/.claude/projects/.../*.jsonl`, 현재 76개·최대 3.6MB) 파싱. `ce-compound`가 하던 일이지만
  단일 SKILL.md·서브에이전트 없음 결정과 충돌한다. `/clear` 뒤의 복구 경로는 브랜치 증거 모드가 맡는다.
- `CONCEPTS.md` 어휘 수집
- 기존 문서 일괄 갱신(`ce-compound-refresh` 상당). 중복 발견 시 해당 문서 하나만 갱신한다.
- 문제 유형별 전문 리뷰어 서브에이전트
- 학습 문서를 여러 건 한 번에 쓰기. 한 실행에 하나 — 중복 확인과 교차 참조가 그것을 전제한다.
