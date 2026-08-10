# Superpowers 제거와 Matt 하네스 전환 설계

**작성일**: 2026-08-10
**대상 저장소**: `~/.claude`
**작업 브랜치**: `refactor/remove-superpowers`

## 1. 배경과 목표

2026-08-07에 compound-engineering을 걷어내고 Superpowers 단독 하네스로 수렴시켰다(`docs/plans/2026-08-07-superpowers-only-harness.md`). 사흘 뒤 그 결정을 뒤집는다.

계기는 두 가지다. mattpocock-skills 플러그인을 설치해 두 하네스가 공존하게 됐고, Opus 5의 자체 검증 능력이 충분한데 Superpowers가 중복 검증으로 토큰을 소모한다는 판단이 섰다.

**목표**: `~/.claude` 하네스에서 Superpowers를 완전히 제거하고 라우팅을 `/ask-matt`로 옮긴다. 자동 강제 라우팅을 걷어내 실행 비용을 없앤다.

## 2. 결정 근거

### 2.1 비용은 상주가 아니라 실행에서 난다

실측치다.

| 항목 | 크기 | 성격 |
|---|---|---|
| `using-superpowers/SKILL.md` | 3,063 B | 매 startup·clear·compact 주입 |
| 스킬 13개 description 합계 | 740 B | 스킬 목록 리스팅 |
| `subagent-driven-development/SKILL.md` | 28,077 B | 호출 시 로드 |
| `writing-skills/SKILL.md` | 26,360 B | 호출 시 로드 |
| `test-driven-development/SKILL.md` | 9,015 B | 호출 시 로드 |

상주 비용은 대략 1,000에서 1,500 토큰 수준이다. 실행 비용은 두 자릿수 배 크고, 여기에 SDD가 태스크마다 서브에이전트 둘(구현·리뷰)을 띄우는 비용이 얹힌다.

실행 비용을 부르는 것은 플러그인의 존재가 아니라 `CLAUDE.md`의 MANDATORY 규칙이다. 그래서 이번 작업의 무게중심은 플러그인 토글이 아니라 `CLAUDE.md` 규정 삭제에 있다.

### 2.2 걷어내는 것은 검증이 아니라 중복 층이다

Superpowers의 종료 두 단계는 이미 규칙 파일과 내용이 겹친다.

- `verification-before-completion`(3,646 B)이 지시하는 것은 `rules/boundaries.md` Always 티어의 `uv run ty check`·`ruff check`·`ruff format` 규정과 같다.
- `finishing-a-development-branch`(7,022 B)가 지시하는 것은 `rules/git-workflow.md`의 커밋 포맷·브랜치 명명·PR 워크플로와 같다.

훅도 마찬가지다. `hooks/workflow-stage-inject.sh`의 `*capturing-learnings)` case가 주입하는 요소 일곱 개(비자명·재발·트리 밖 판정, `docs/solutions` 경로, `file:line` 인용, 세션 모드, 브랜치 증거 모드)가 `skills/capturing-learnings/SKILL.md` 217줄 안에 전부 있다.

규칙에 이미 있는 내용을 스킬이 다시 로드해서 반복하는 구조다. 이 층만 제거하며 규칙 자체는 손대지 않는다.

### 2.3 라우터가 둘일 이유가 없다

`CLAUDE.md`의 High-Priority Workflow Skills 표는 라우터다. mattpocock의 `/ask-matt`도 라우터다. 둘 중 하나는 잉여다.

`ask-matt`를 남긴다. `disable-model-invocation: true`라 칠 때만 로드되므로 상주 비용이 0이다. mattpocock 저장소의 `CLAUDE.md`는 "라우터가 거짓말하면 버그"로 취급하며 스킬 변경 시마다 갱신을 약속한다. `CLAUDE.md` 표는 매 세션 값을 치르면서 유지보수도 직접 해야 한다.

## 3. 목표 상태와 선택한 성질

Superpowers를 완전히 제거하고 Matt을 메인 하네스로 삼는다.

`ask-matt`는 스스로 발동하지 않는다. 이후 라우터는 사용자가 `/ask-matt`를 칠 때만 존재한다. 얇은 하네스의 정의이므로 의도된 결과다. 나중에 발견한 부작용이 아니라 선택한 성질로 기록한다.

## 4. 파일별 변경

### 4.1 수정

| 파일 | 참조 수 | 작업 |
|---|---|---|
| `CLAUDE.md` | 5 | Planning Trigger 섹션(조건 5개·Exempt 목록·`/clear` 판단·Plan Mode 문단)과 Plan Persistence 삭제. Mandatory Skill Protocol의 죽은 Superpowers 예외 3개 삭제 |
| `README.md` | 11 | 메인 하네스 서술·파이프라인 다이어그램·플러그인 표를 Matt 기준으로 재작성 |
| `scripts/install.sh` | 2 | 존재 확인 루프와 주석의 잔여 참조 정리 |
| `settings.json` | 1 | `enabledPlugins.superpowers`를 `false`로. 함께 `PostToolUse`의 `matcher:"Skill"` 등록도 제거한다(문자열 매치에는 안 잡히지만 삭제될 훅을 가리킨다) |

`CLAUDE.md`에서 삭제하지 않는 것: Scope Clarification·Core Principles·TODO Management·RTK·CodeGraph 마커 블록·graphify 섹션.

### 4.2 삭제

- `hooks/workflow-stage-inject.sh` 전체. case 8개 중 7개가 Superpowers 스킬이고 나머지 하나는 §2.2에서 확인한 대로 순수 중복이다.

### 4.3 손대지 않음

- `rules/korean-style.md`·`skills/capturing-learnings/SKILL.md`·`.gitignore`의 `docs/superpowers/` 참조. 실행 중인 스킬을 가리키는 포인터가 아니라 디렉터리 경로다. 이름을 바꾸면 편집만 늘고 얻는 것이 없다.
- `TODO.md`. 2026-08-07 작업의 기록물이지 배선이 아니다.
- `projects/-Users-jayhan-workspaces-im-not-ai/memory/planning-tool-ce-plan-over-writing-plans.md`. 삭제된 `rules/hybrid-workflow.md`와 꺼진 `/ce-plan`을 가리키는 죽은 메모리다. Tier 1이라 사용자 판단 영역이다. 이번 작업에서는 보고만 한다.
- `skillOverrides` 30개. 전부 사용자 스킬이고 Superpowers 항목이 없다.

`docs/superpowers/specs/`는 동결한다. 이 문서가 마지막 입주자이고 이후 스펙은 Matt의 `to-spec`이 처리한다.

## 5. 잃는 것

| 잃는 것 | 대체 |
|---|---|
| `verification-before-completion` | `rules/boundaries.md` Always 티어 |
| `finishing-a-development-branch` | `rules/git-workflow.md` |
| 훅의 `capturing-learnings` case | `skills/capturing-learnings/SKILL.md` 본문 |
| `CLAUDE.md` 스킬 표 | `/ask-matt` |
| `using-git-worktrees` | 없음 |
| `dispatching-parallel-agents` | 없음 |
| `receiving-code-review` | 없음 |

아래 셋은 대체물을 만들지 않는다. 필요해지면 그 시점에 판단한다.

## 6. 계획 산출물

`docs/plans/` 6개는 legacy로 동결한다. `rules/boundaries.md` Never 티어의 계획 파일 삭제 금지 규칙도 그대로 유지한다. 과거 기록의 보호가 목적이므로 새 경로로 옮기지 않는다.

새 작업의 티켓은 `.scratch/<feature>/issues/<NN>-<slug>.md`로 간다. `.gitignore`가 allowlist 방식(`/*` 전부 무시 후 opt-in)이라 `.scratch/`는 자동으로 추적 제외된다. 공개 저장소이지만 별도 조치가 필요 없다.

## 7. `~/.claude` 특수 제약

`/setup-matt-pocock-skills`는 저장소 루트의 `CLAUDE.md`를 편집한다. `~/.claude`에서 실행하면 Tier 0 파일을 건드리므로 이 저장소에서는 돌리지 않는다.

트래커 미설정 상태에서 Matt 스킬의 동작은 이렇다.

- `to-tickets`: 로컬 마크다운 경로(`.scratch/<feature-slug>/issues/`)를 지원한다.
- `wayfinder`: 트래커가 제공되지 않으면 로컬 마크다운을 기본값으로 쓰라고 명시한다.
- `to-spec`: 폴백 문구가 없다. `~/.claude` 작업에서 쓸 때는 로컬 마크다운으로 간다고 매번 지정해야 한다.

## 8. 실행 순서

2026-08-07 계획에서 검증된 두 가지를 재사용한다.

**포인터 먼저·삭제 나중.** 그 계획이 Task 4(`CLAUDE.md`)를 Task 6(삭제)보다 앞에 둔 이유가 매달린 포인터 방지였다. 여기서도 문서 재작성이 먼저이고 플러그인 토글이 마지막이다.

**마지막에 잔여 참조 grep.** 그 계획 §5다. 개정 이력이 보여준 범위 누락은 정확히 아무도 grep하지 않은 자리(`install.sh` 존재 확인 루프, `memory-templates/`)에서 나왔다. `scripts/`와 `memory-templates/`를 포함해 훑는 단계를 종료 검증으로 둔다.

태스크 순서:

1. `CLAUDE.md` 재작성
2. `README.md` 재작성
3. 훅 삭제와 `settings.json` PostToolUse 등록 제거, `scripts/install.sh` 정리
4. `enabledPlugins.superpowers`를 `false`로
5. 잔여 참조 grep 검증

각 태스크가 커밋 하나다. 태스크 단위로 되돌릴 수 있고 어느 중간 커밋에도 매달린 포인터가 없다.

워킹트리에 이미 있던 `settings.json` 변경(graphify 훅 키 순서 재정렬, `mattpocock-skills` 활성화)은 mattpocock 설치의 부산물이다. 이번 작업의 전제에 해당하므로 태스크 4에서 함께 처리한다.

## 9. 검증

실행 가능한 테스트 스위트가 없는 설정·문서 저장소다. 각 태스크의 RED/GREEN은 정적 검사로 대체한다.

- `grep` 카운트: 편집 전과 후를 각각 실행한다. 편집 전 값이 계획의 기대값과 다르면 멈추고 보고한다.
- `jq . settings.json`: JSON 유효성.
- 종료 검증: `~/.claude` 전체에서 `superpowers` 문자열을 훑어 남은 것이 §4.3의 손대지 않기로 한 항목뿐인지 확인한다.

플러그인 비활성화의 실제 반영은 새 세션에서만 확인된다. 태스크 4 이후 사용자가 재시작하고 `/context`로 Superpowers 스킬 13개가 사라졌는지 확인한다.

## 10. 명시적 비목표

- 검증 자체를 없애지 않는다. `rules/boundaries.md`와 `rules/git-workflow.md`는 그대로 남는다.
- `docs/superpowers/` 디렉터리 이름을 바꾸지 않는다.
- Superpowers를 대체할 커스텀 스킬을 새로 만들지 않는다.
- 프로젝트 저장소의 설정은 손대지 않는다. 대상은 `~/.claude` 하나다.
