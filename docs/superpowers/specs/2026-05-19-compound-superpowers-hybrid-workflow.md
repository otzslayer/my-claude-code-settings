# Compound + Superpowers Hybrid Workflow — Design Spec

**작성일**: 2026-05-19
**대상**: jay의 Claude Code 글로벌 하네스 (`~/.claude` / `~/my-claude-code-settings`)
**컨텍스트**: Python Agentic AI 시스템 및 백엔드 작업 전반 (프로젝트 무관)
**상태**: draft — 사용자 검토 대기

---

## 1. Goal

Superpowers, Compound Engineering, Plannotator, CodeGraph, graphify, RTK, .remember 등 이미 설치되어 있는 도구들을 **하나의 일관된 7단계 파이프라인**으로 묶는다. 두 참고 자료(Reddit 11-step, 티스토리 7-step)가 추천한 흐름을 plannotator 자동 게이트가 이미 작동 중인 환경에 맞춰 재단했다.

핵심 원칙:
- **레이어 분리**: Superpowers = 스킬·게이팅, CE = 워크플로우·학습 누적, CodeGraph = 코드 인텔리전스(읽기 전용), graphify = 시각화, plannotator = 검토 게이트, RTK = 토큰 인프라.
- **현재 자동화 보존**: ExitPlanMode → plannotator 자동 발동 게이트를 깨지 않는다.
- **CE의 고유 가치 흡수**: ce-plan의 codebase 리서치, ce-work의 worktree·parallel safety, ce-code-review의 다중 리뷰어, ce-compound의 학습 누적.
- **사용자 메모리 시스템 보호**: 전역 CLAUDE.md와 `~/.claude/projects/.../memory/` auto memory는 자동 변경 금지. ce-compound 산출물은 프로젝트 로컬 `docs/solutions/`에만 둔다.
- **Compound 학습 루프 닫기**: `docs/solutions/`는 write-only 저장소가 아니다. Phase 2의 `/ce-plan` 리서치 단계에서 `ce-learnings-researcher`가 같은 디렉토리를 읽어 과거 학습을 plan 컨텍스트로 주입한다 (게이트: 파일 3개 이상일 때만). write(ce-compound) + read(ce-learnings-researcher) = compound의 핵심 가치.

---

## 2. 전체 파이프라인

각 Phase의 권장 실행 모델·effort는 §3.5 "단계별 모델 정책" 참조.

```
┌────────────────────────────────────────────────────────────────────┐
│  Phase 1: Spec (의사결정 아티팩트)                                 │
│    superpowers:brainstorming                                       │
│      └ 시작 시 95% confidence interview opener 적용                │
│      └ (옵션) graphify 도메인 그래프 → spec 첨부                   │
│    → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md           │
│    → 사용자 검토 → 승인                                            │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼  /clear (fresh context)
┌────────────────────────────────────────────────────────────────────┐
│  Phase 2: Plan (Plan Mode 트리거 조건 만족 시)                     │
│    1. Plan Mode 진입 (Shift+Tab)                                   │
│    2. /ce-plan                                                     │
│         └ 병렬 리서치 에이전트가 git/codebase 패턴 탐색            │
│         └ CodeGraph 보조: codegraph_explore,                       │
│           codegraph_callers/impact로 패턴 의존성 자동 수집         │
│         └ ce-learnings-researcher: docs/solutions/에서             │
│           과거 학습 조회 (파일 3개 이상일 때만 발동)               │
│         └ docs/plans/<draft>.md 작성                               │
│    3. ExitPlanMode 호출                                            │
│         └ plannotator hook 자동 발동 → browser UI 검토             │
│         └ 사용자: 어노테이션 / 승인                                │
│    4. 어노테이션 반영 후 최종 docs/plans/YYYY-MM-DD-<summary>.md   │
│    5. /clear                                                       │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼  fresh context, plan 파일 입력
┌────────────────────────────────────────────────────────────────────┐
│  Phase 2': Build                                                   │
│    1. superpowers:test-driven-development                          │
│         └ RED → GREEN → REFACTOR (pytest 기반 가정)                │
│         └ 면제: 타입 픽스, 린터 픽스, 단일 파일 리네임, 트리비얼   │
│    2. /ce-work <plan-path>                                         │
│         └ 내장 parallel subagents (worktree isolation)             │
│         └ parallel safety check + file collision detection         │
│         └ 읽기 전용. 편집 전 codegraph_impact로 영향범위 파악      │
│    3. /ce-code-review                                              │
│         └ 6+ 리뷰어 앙상블                                         │
│           (correctness, security, perf, testing,                   │
│            maintainability, adversarial)                           │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│  Phase 3: Verify, Learn & Ship                                     │
│    1. superpowers:verification-before-completion                   │
│         └ CLAUDE.md "Before Declaring Done" 체크리스트 매핑        │
│         └ uv run ty check src/                                     │
│         └ uv run ruff check --fix . && uv run ruff format .        │
│         └ uv run pytest -v                                         │
│    2. /ce-compound mode:headless (Full)                            │
│         └ 5개 서브에이전트로 docs/solutions/<problem>.md 생성      │
│         └ CLAUDE.md·auto memory는 자동 변경 금지                   │
│         └ (옵션) graphify로 docs/solutions/<problem>.graph.md      │
│    3. superpowers:finishing-a-development-branch                   │
│         └ tests 검증 → 옵션 제시 → 커밋·푸시·PR                    │
│         └ 한국어 커밋 메시지 포맷 (rules/git-workflow.md)          │
└────────────────────────────────────────────────────────────────────┘
```

---

## 3. 컴포넌트 책임 분담

### 3.1 Phase 1 — Spec

| 도구 | 역할 |
|---|---|
| `superpowers:brainstorming` | 메인. 시작 질문에 "95% confidence interview" 패턴 통합 |
| `graphify` | (옵션) 도메인 모델 그래프 → spec md에 첨부 |
| `superpowers:writing-skills` | brainstorming 산출물이 새 스킬 후보일 때만 |

**95% confidence interview opener 통합 방식**: brainstorming 스킬의 첫 질문을 다음 형태로:
> "지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95% 확신이 생길 때까지 질문을 던지겠습니다 — 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다."

이는 CLAUDE.md "Mandatory Skill Protocol" 표에 별도 행을 추가하지 않고, brainstorming의 첫 turn에 자연스럽게 녹인다.

### 3.2 Phase 2 — Plan

| 도구 | 역할 |
|---|---|
| Plan Mode | 게이트. Complex task 트리거(3+ 파일·새 모듈/패턴·새 의존성·public API/스키마·명시 요청) |
| `/ce-plan` | 메인 plan 작성. 병렬 리서치, deepening pass 활용 |
| CodeGraph MCP | ce-plan 리서치 보조. `codegraph_explore`/`codegraph_callers`/`codegraph_impact`로 심볼·의존성·영향 범위 자동 수집 (읽기 전용) |
| `ce-learnings-researcher` | docs/solutions/ 과거 학습 조회. compound 루프의 **read** 측 (write는 §3.4 ce-compound). 게이트: 파일 3개 이상일 때만 발동 |
| `ExitPlanMode` | plannotator hook 발동 트리거 |
| plannotator | browser UI 어노테이션. 어노테이션 → 모델이 반영 후 재제출 가능 |

**경로 정합 정책**: ce-plan은 `docs/plans/<draft>.md`에 작성. Plan Mode system message가 다른 경로를 지정하더라도 ce-plan 경로를 사용한다. ExitPlanMode 호출 시 plan 인자에는 ce-plan 결과 파일의 **요약 + 절대 경로**를 넣는다.

> ⚠️ **검증 필요**: Plan Mode 안에서 ce-plan의 Write 호출이 실제로 통과하는지, 그리고 plannotator가 ExitPlanMode 호출 시점에 docs/plans/<draft>.md를 읽어가는지 (또는 plan 인자만 읽는지)는 첫 적용 시 확인.

### 3.3 Phase 2' — Build

| 도구 | 역할 |
|---|---|
| `superpowers:test-driven-development` | RED 작성. 면제 조건 명시 |
| `/ce-work <plan>` | 메인 실행. 내장 worktree·parallel safety |
| CodeGraph MCP | 읽기 전용 — 코드 편집은 표준 `Edit`/`Write`, 편집 전 `codegraph_impact`로 blast radius 파악 — `boundaries.md` 정책 그대로 |
| `/ce-code-review` | 다중 리뷰어 앙상블. ensemble 결과는 PR/이슈 본문에 포함 |

**면제 조건 (TDD 스킵 허용)**:
- 타입 어노테이션만 추가
- ruff 자동 픽스
- 단일 파일 리네임 (behavior 변경 없음)
- 코멘트/docstring 정리
- 의존성 버전만 올림
- 1줄~수십 줄의 명백한 리팩토링 (기존 테스트가 그대로 통과)

면제에 해당하면 직접 ce-work 또는 인라인 편집으로 진행하되, 변경 후 `pytest` 한 번은 돌린다.

### 3.4 Phase 3 — Verify, Learn & Ship

| 도구 | 역할 |
|---|---|
| `superpowers:verification-before-completion` | "Before Declaring Done" 체크리스트 강제 |
| `/ce-compound mode:headless` | Full 모드로 docs/solutions/ 자동 생성. 인터랙티브 프롬프트 회피 |
| graphify | (옵션) solutions의 핵심 관계 시각화 |
| `superpowers:finishing-a-development-branch` | 커밋·푸시·PR 워크플로우 |

**ce-compound headless 고정 이유**:
- Full/Lightweight 선택 프롬프트가 매 작업마다 뜨면 마찰
- 세션 히스토리 검색 질문도 매번 답해야 함
- `.remember/`가 이미 세션 메모리 담당, ce-compound는 **문제 해결 사례 누적**으로 역할 분리
- Headless = Full 결과지만 무질문. "What's next?" 메뉴도 없음

### 3.5 단계별 모델 정책

각 단계의 권장 실행 모델과 reasoning effort. 운영 가이드 `rules/hybrid-workflow.md` "단계별 모델 정책"과 1:1 정합을 유지한다.

**배치 원칙**:
- **Opus · effort `xhigh`** — 개방형 추론이고 틀리면 비용이 큰 일(한 번 어긋나면 하위 단계 전체 오염).
- **Sonnet · effort `high`** — 확정된 아티팩트(spec/plan)에 대한 실행. 판단이 아닌 수행 중심.

| 단계 / 스킬 | 모델 | effort | 근거 |
|---|---|---|---|
| Phase 1 `superpowers:brainstorming` | Opus | `xhigh` | 의도 파악·엣지케이스 발굴 |
| Phase 2 `/ce-plan` | Opus | `xhigh` | 아키텍처 결정·트레이드오프·리서치 종합 |
| Phase 2' `superpowers:test-driven-development` | Sonnet | `high` | plan 기반 테스트 작성 |
| Phase 2' `/ce-work` | Sonnet | `high` | 확정된 plan 실행 |
| Phase 2' `/ce-code-review` | Opus(리뷰어) | `xhigh` | 리뷰어 subagent 레벨 권장. 세션은 Sonnet 유지(세션 중 전환 없음 — 아래 메커니즘 참조) |
| Phase 3 `superpowers:verification-before-completion` | Sonnet | `high` | 명령 실행·검증 |
| Phase 3 `/ce-compound mode:headless` | Sonnet | `high` | 정형 학습 문서화 |
| Phase 3 `superpowers:finishing-a-development-branch` | Sonnet | `high` | 커밋·푸시·PR |
| `superpowers:systematic-debugging` | Opus | `xhigh` | 근본 원인 추적 |
| 면제 케이스 (타입/린터/리네임/트리비얼) | Sonnet | `high` | 단순 작업 |

**전환 메커니즘 (경계에서 수동 안내)**:
- **제약**: 메인 에이전트는 세션 도중 스스로 모델을 바꿀 수 없다. 전환은 사용자의 `/model`·`/effort` 또는 `/clear` 후 새 세션에서만 가능.
- 각 단계(특히 `/clear` 후 새 세션) 시작 시 그 단계의 권장 모델·effort를 announce하고 현재 설정과 다르면 사용자에게 전환을 안내한 뒤 진행한다(강제 금지). 모델이 자기 effort를 항상 조회할 수 있는 건 아니므로 점검보다 announce가 안전하다.
- **ce-code-review 예외**: Phase 2' 내부라 `/clear` 경계가 아니다. 세션 모델은 Sonnet high를 유지하고(세션 중 `/model` 전환의 전체 히스토리 캐시 재로딩 비용 회피), "Opus xhigh"는 6+ 리뷰어 **subagent** 레벨을 뜻한다. 리뷰어 모델 지정은 강제하지 않는다(플러그인 frontmatter pin 미채택 — Q1에서 사용자가 '경계 수동 안내' 선택).
- 현재 글로벌 디폴트(`~/.claude/settings.json`): `model: Opus`, `effortLevel: xhigh`. Opus 단계는 전환 불필요, Sonnet 단계 진입 시 `/model sonnet`·`/effort high` 안내. Sonnet 4.6은 `xhigh` 미지원(기본 `high`).

### 3.6 유닛 세분도 · 실행 전략 (1시간 캐싱 하의 토큰 규율)

운영 가이드 `rules/hybrid-workflow.md` "Unit granularity & execution strategy" 절과 1:1 정합을 유지한다.

1시간 프롬프트 캐싱에서는 캐시 **write가 2× base input**(read는 0.1×)이고, 서브에이전트 스폰마다 자기 prefix(CLAUDE.md + 스킬 주입 + 유닛 패킷)를 fresh 2× write로 재확립한다. 따라서 줄일 수 있는 지배적 비용은 토큰 단가가 아니라 **스폰 개수**다. 단계별 기본값 둘:

- **굵은 유닛 (Phase 2, `/ce-plan`)** — 응집도(공유 파일·타입·의존 사슬)로 Implementation Units를 더 굵고 적은 U-ID로 묶는다. 유닛 수 감소 = 스폰 수 감소 = 2× prefix write 감소. 이것이 1차 레버이며 실행이 아니라 plan에 있다. plan을 세분해 보이려고 응집된 변경을 잘게 쪼개지 않는다.
- **serial 서브에이전트 (Phase 2', `/ce-work`)** — wall-clock 속도가 명시적 우선순위가 아니면 병렬 fan-out보다 serial 실행을 선호한다. 병렬의 유일한 이득은 지연시간이며, 비용 최적화 시엔 merge·contention·통합 오버헤드를 더한다(ce-work가 병렬 배치를 3-5 워커로 캡하는 이유). serial은 서브에이전트의 두 장점(깨끗한 유닛별 롤백, 린 오케스트레이터 컨텍스트)을 병렬 세금 없이 유지한다.

**감수하는 트레이드오프**: wall-clock 속도와 유닛 간 가시성을 포기한다(격리된 워커는 서로의 떠오르는 패턴을 못 봄 — ce-work의 "Simplify as You Go" 패스가 일부 완화). 유닛 간 통합이 깨끗한 롤백보다 중요한 강결합 클러스터는, 대신 그 클러스터를 메인 컨텍스트에서 인라인 실행하고 stage 경계에서 `/clear`한다 — 전역이 아니라 클러스터별로 선택. inline vs 서브에이전트는 토큰상 대략 무승부이고, 진짜 이득은 굵은 유닛에서 오는 스폰 개수 감소로 두 실행 모드 모두에 적용된다.

---

## 4. 메모리 · 문서 레이어 정리

| Tier | 위치 | 책임 | 변경 주체 |
|---|---|---|---|
| 0. 글로벌 행동 규칙 | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | 협업 원칙, 게이팅 | **사용자 수동만** |
| 1. 글로벌 메타 메모리 | `~/.claude/projects/.../memory/`, `~/.claude/.remember/` | user/feedback/project/reference, 세션 단위 메모리 | 모델이 user/feedback 발화에 한해 자동 갱신 |
| 2. 프로젝트 의사결정 | `<proj>/docs/superpowers/specs/`, `<proj>/docs/plans/` | spec, plan | 모델이 작성, 사용자 승인 게이트 |
| 3. 프로젝트 학습 누적 | `<proj>/docs/solutions/` | ce-compound 산출물 (write) + ce-learnings-researcher 조회 (read) | 모델 자동 (headless) |
| 4. 프로젝트 시각화 | `<proj>/graphify-out/`, `<proj>/docs/solutions/*.graph.md` | graphify 산출물 | 사용자 또는 모델 호출 시 |
| 5. 프로젝트 진행 추적 | `<proj>/TODO.md` | 후속 작업 목록 | 양쪽 모두 |

**정책**:
- Tier 0/1로의 ce-compound 자동 반영은 금지. 사용자가 Tier 3의 솔루션 문서를 읽고 가치 있다고 판단되면 손으로 Tier 0/1에 옮긴다.
- Tier 3는 write-only 저장소가 아니다. Phase 2의 ce-plan 리서치 단계에서 `ce-learnings-researcher`가 Tier 3를 읽어 plan에 반영 → compound 학습 루프가 닫힌다.
- ce-learnings-researcher 호출 게이트: `docs/solutions/`에 파일이 **3개 이상**일 때만 발동. 미만이면 검색 노이즈가 신호를 압도하므로 생략.

---

## 5. 트리거 정의

### 5.1 풀 파이프라인 발동 조건 (CLAUDE.md Plan Mode 트리거와 동일)

다음 중 하나 만족 시:
- 3+ 파일 변경
- 새 모듈·패턴·아키텍처 결정
- 새 의존성 추가
- public API 또는 데이터 스키마 변경
- 사용자 명시 요청 (`"이거 제대로 설계해줘"`, `"plan 짜줘"` 등)

### 5.2 면제 (Phase 1·2 스킵, 직접 Phase 2'부터)

- 타입/린터 픽스
- 단일 파일 비-behavior 변경
- 명시적으로 "rename only", "format only" 같은 단순 작업

### 5.3 부분 발동

- README 광범위 업데이트 → Phase 1 + Phase 3 (build 단계 없음)
- eval 결과 분석/회귀 → Phase 3의 ce-compound만 (artifacts/*.csv 입력)

---

## 6. 하네스 변경 사항

### 6.1 `~/my-claude-code-settings/CLAUDE.md` 수정

**Plan Persistence 절** 교체 (현재 superpowers:writing-plans 기준 → ce-plan 기준):

```markdown
**Plan Persistence (MANDATORY — Complex tasks)**:

1. Plan Mode 진입 (Shift+Tab)
2. /ce-plan으로 docs/plans/<draft>.md 작성 (ce-plan 인터랙티브 질문 응답)
3. ExitPlanMode 호출 — plan 인자에 ce-plan 결과 경로·요약 포함
4. plannotator hook 자동 발동 → browser UI에서 어노테이션·승인
5. 어노테이션 반영 또는 승인 → docs/plans/YYYY-MM-DD-<summary>.md 최종
6. /clear → 새 세션에서 ce-work로 실행
```

**Mandatory Skill Protocol 표** 보강:

| Trigger | Skill |
|---|---|
| 새 기능/컴포넌트/behavior 변경 | `superpowers:brainstorming` (시작 시 95% confidence opener) |
| Multi-step 구현 (Plan Mode 트리거 만족) | `ce-plan` (Plan Mode 안에서) |
| Plan 실행 | `ce-work <plan-path>` |
| 구현 마무리 | `superpowers:test-driven-development` + `ce-work` + `ce-code-review` |
| 검증 | `superpowers:verification-before-completion` |
| 학습 누적 | `/ce-compound mode:headless` (작업 완료 후 자동) |
| 커밋·푸시·PR | `superpowers:finishing-a-development-branch` |
| 버그 / 실패 테스트 | `superpowers:systematic-debugging` (변경 없음) |

### 6.2 `~/my-claude-code-settings/rules/` 신규 파일

**`rules/hybrid-workflow.md`** (신규) — 본 spec의 운영 가이드 요약본. CLAUDE.md "Rules Directory" 절에 한 줄 추가:
```markdown
- `hybrid-workflow.md` — Compound + Superpowers 하이브리드 파이프라인 운영 규칙
```

### 6.3 `~/.claude/settings.json` hooks

**변경 없음**. plannotator hook은 ExitPlanMode 가로채기를 이미 처리. PostToolUse 백업 훅(방식 2)은 채택 안 함 → 중복 발동 방지.

### 6.4 boundaries.md 수정

ce-plan / ce-work 단계의 CodeGraph 활용을 명시:
```markdown
### Tool Usage (token-optimized)
- ...(기존)...
- **ce-plan 리서치 단계**: CodeGraph `codegraph_explore`/`codegraph_callers`/`codegraph_impact`로 패턴·의존성 자동 수집
- **ce-work 구현 단계**: 편집 전 `codegraph_impact`로 영향 범위 파악 후 `Edit` (CodeGraph는 읽기 전용)
```

### 6.5 auto memory 추가

새 feedback 메모리 작성:
- 파일: `~/.claude/projects/-home-jay--claude/memory/feedback_hybrid_workflow.md`
- 내용: 본 spec 경로 참조 + "ce-compound 산출물은 CLAUDE.md/auto memory에 자동 반영 금지, 사용자 검토 후 수동만"
- `MEMORY.md` 인덱스에 한 줄 추가

### 6.6 단계별 모델 정책 추가 (2026-06-04)

비용 효율을 위해 단계마다 실행 모델·effort를 차등 지정(개방형 추론=Opus xhigh, 실행=Sonnet high). 반영 위치:
- `CLAUDE.md` Mandatory Skill Protocol 표에 "Model · effort" 열 + 정책 단락 추가, Plan Persistence 6단계에 Plan→Build 전환 안내
- `rules/hybrid-workflow.md`에 "단계별 모델 정책" 절 신설 + 7-phase 다이어그램·면제·부분발동에 모델 표기 (정식 정의처)
- 본 spec §3.5 (위)

핵심 제약: 메인 에이전트는 세션 중 자가 모델 전환 불가 → `/clear` 경계에서 사용자에게 `/model`·`/effort` 전환을 안내하는 방식 채택.

### 6.7 유닛 세분도 · 실행 전략 추가 (2026-07-02)

토큰 사용량 리포트 분석(1시간 캐싱: write 2×, 서브에이전트 스폰이 지배적 비용) 결과 "굵은 유닛 + serial 서브에이전트"를 기본값으로 채택. 반영 위치:
- `rules/hybrid-workflow.md`에 "Unit granularity & execution strategy" 절 신설 (정식 정의처)
- 본 spec §3.6 (위)

핵심: 스폰 개수 감소가 1차 레버이고 `/ce-plan`의 유닛 묶기에서 결정된다. inline vs subagent는 토큰상 무승부이므로 실행 모드보다 유닛 세분도가 우선.

---

## 7. 에러 / 엣지 케이스 처리

| 상황 | 정책 |
|---|---|
| Plan Mode 안에서 ce-plan의 Write 차단됨 | 첫 적용 시 발견되면 **방식 2 (PostToolUse 훅)로 fallback**. 결과를 §9 Open Questions에 기록 후 spec 갱신 |
| plannotator가 ExitPlanMode 가로채기에 실패 | `/plannotator-annotate docs/plans/<file>` 수동 호출. CLAUDE.md에 fallback 명시 |
| ce-work parallel subagent가 worktree에서 충돌 | ce-work 내장 정책 그대로 (abort → serial 재시도) |
| ce-compound headless가 잘못된 분류를 생성 | docs/solutions/는 모델 자동 생성 영역이지만 git tracked. 사용자가 수동 정정 또는 삭제 가능 |
| 대용량 입력으로 ce-compound 토큰 초과 | 입력 시 요약·헤더만 전달. RTK가 일부 압축 |
| TDD 면제 판단이 애매 | 모델이 사용자에게 확인 (`AskUserQuestion`) — boundaries.md "Surgical Changes" 정신 적용 |
| `docs/solutions/`가 비어있거나 파일 2개 이하 | ce-learnings-researcher 호출 생략. 신호 부족 상태의 조회는 무관 솔루션을 plan 컨텍스트로 끌어들여 오히려 사고를 흐림 |

---

## 8. 테스트 / 검증 계획

본 spec 자체에 대한 검증:

1. **빈 임시 프로젝트에서 dry run** — 가장 간단한 Python 패키지를 만들고 brainstorming → Plan Mode → ce-plan → ExitPlanMode → plannotator → ce-work → verification 전 흐름을 한 번 돌려본다. Plan Mode에서 Write 차단 여부 실증.
2. **소규모 변경에 적용 (Phase 1 skip 시나리오)** — Phase 1 skip, Phase 2 minimal plan, Phase 3 강제로 면제 트리거 동작 확인.
3. **풀 파이프라인 변경에 적용** — 새 모듈/패턴이 들어가는 변경에서 ce-plan 리서치 품질·plannotator 검토 흐름·ce-compound 자동 산출 확인.
4. **TODO.md 갱신 흐름 확인** — finishing-a-development-branch 후 TODO.md가 적절히 정리되는지.

각 단계에서 측정:
- 토큰 사용량 (RTK gain)
- 실제 잡음 발생 위치 (어디서 모델이 헤매는지)
- plannotator 자동 발동 성공률

---

## 9. 후속 결정 / Open Questions

1. **CodeGraph `.codegraph/` 캐시 / graphify `graphify-out/` 디렉토리의 글로벌 `.gitignore` 정책** — 프로젝트별로 둘지 글로벌 ignore로 둘지.
2. **ce-doc-review를 정기 트리거에 자동 묶을지** — 큰 README/AGENTS.md를 운영하는 프로젝트에 가치.
3. **ce-sessions를 .remember/와 어떻게 정렬할지** — 둘 다 세션 분석. 역할 분리 또는 통합 결정 필요.
4. **subagent-driven-development를 완전 폐기하지 않고 보존할지** — ce-work 내장 병렬화 채택했지만 superpowers 스킬도 유지할 가치 있는지.

위 4건은 본 spec 적용 후 첫 두세 사이클을 돌려본 후 의사결정을 권장.

---

## 10. 다음 단계 (사용자 검토 후)

이 spec 승인되면:
1. `writing-plans` 스킬을 호출해 구현 plan 작성 (CLAUDE.md, rules/hybrid-workflow.md, boundaries.md 변경 task로 분해)
2. plan 검토 → `/clear` → ce-work로 실행
3. 첫 dry run (위 §9.1) 후 spec 갱신

— END OF SPEC —
