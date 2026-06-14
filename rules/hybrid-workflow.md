# Compound + Superpowers 하이브리드 워크플로우

Plannotator 자동 게이트가 작동하는 환경에서 Superpowers·Compound Engineering·CodeGraph·graphify·RTK·.remember를 하나의 7단계 파이프라인으로 묶는 운영 규칙.

**Source of truth (spec)**: `~/.claude/docs/superpowers/specs/2026-05-19-compound-superpowers-hybrid-workflow.md`

본 문서는 spec 운영 가이드 요약본이다. 단계명·도구명·트리거 조건은 spec과 1:1 일치해야 한다. 본 문서와 spec이 충돌하면 spec이 우선이며, 본 문서를 갱신해 정합을 맞춘다.

---

## 7단계 파이프라인 (압축본)

각 단계 옆 `[모델·effort]`는 권장 실행 모델이다. 정식 정의·전환 메커니즘은 아래 "단계별 모델 정책" 절 참조.

```
Phase 1: Spec  ▸ Opus · xhigh
  superpowers:brainstorming  [Opus·xhigh]  (시작 시 95% confidence opener)
  (옵션) graphify
  → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
  → 사용자 검토 · 승인
       │
       ▼  /clear  (다음 단계도 Opus xhigh — 전환 불필요)
Phase 2: Plan  ▸ Opus · xhigh  (Plan Mode 트리거 만족 시)
  1. Plan Mode 진입 (Shift+Tab)
  2. /ce-plan  [Opus·xhigh]  (병렬 리서치 + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: docs/solutions/ 과거 학습 조회 — 파일 3개 이상일 때만)
              → docs/plans/<draft>.md
  3. ExitPlanMode  (plan 인자에 ce-plan 결과 경로·요약 포함)
  4. plannotator hook 자동 발동 → browser UI 어노테이션·승인
  5. docs/plans/YYYY-MM-DD-<summary>.md 최종 저장
  6. /clear
       │
       ▼  fresh context, plan 파일 입력  (모델 전환 안내: → Sonnet high)
Phase 2': Build  ▸ Sonnet · high  (세션 모델 고정 — ce-code-review의 리뷰어 subagent만 Opus xhigh 권장)
  7. superpowers:test-driven-development  [Sonnet·high]  (RED → GREEN → REFACTOR, 트리비얼 면제)
  8. /ce-work <plan-path>  [Sonnet·high]  (내장 worktree·parallel safety, 편집 전 codegraph_impact로 영향 범위 파악 후 Edit)
  9. /ce-code-review  [리뷰어 subagent: Opus·xhigh / 세션: Sonnet 유지]  (6+ 리뷰어 앙상블 — 세션 모델 전환 없음)
       │
       ▼
Phase 3: Verify · Learn · Ship  ▸ Sonnet · high
  10. superpowers:verification-before-completion  [Sonnet·high]
       (uv run ty check / ruff check --fix / ruff format / pytest -v)
  11. /ce-compound mode:headless  [Sonnet·high]  (Full, docs/solutions/<problem>.md만)
  12. superpowers:finishing-a-development-branch  [Sonnet·high]  (한국어 커밋 포맷)
```

---

## 단계별 모델 정책

각 단계의 권장 실행 모델과 reasoning effort. 이 절이 **정식 정의처**이며 CLAUDE.md·spec의 모델 표기는 이를 참조한다.

### 배치 원칙

- **Opus · effort `xhigh`** — 개방형 추론이고 틀리면 비용이 큰 일. 한 번 어긋나면 하위 단계 전체가 오염된다.
- **Sonnet · effort `high`** — 확정된 아티팩트(spec/plan)에 대한 실행. 판단이 아니라 수행이 중심.

### 단계별 표

| 단계 / 스킬                                          | 모델         | effort  | 근거                                                                                                      |
| ---------------------------------------------------- | ------------ | ------- | --------------------------------------------------------------------------------------------------------- |
| Phase 1 `superpowers:brainstorming`                  | Opus         | `xhigh` | 의도 파악·엣지케이스 발굴, 여기가 틀리면 전체가 어긋남                                                    |
| Phase 2 `/ce-plan`                                   | Opus         | `xhigh` | 아키텍처 결정·트레이드오프·리서치 종합                                                                    |
| Phase 2' `superpowers:test-driven-development`       | Sonnet       | `high`  | plan 기반 테스트 작성, 실행 중심                                                                          |
| Phase 2' `/ce-work`                                  | Sonnet       | `high`  | 확정된 plan 실행                                                                                          |
| Phase 2' `/ce-code-review`                           | Opus(리뷰어) | `xhigh` | **리뷰어 subagent 레벨** Opus 권장. 세션은 Sonnet 유지(세션 중 전환 없음 — 아래 메커니즘 참조). 강제 아님 |
| Phase 3 `superpowers:verification-before-completion` | Sonnet       | `high`  | 명령 실행·검증, 기계적                                                                                    |
| Phase 3 `/ce-compound mode:headless`                 | Sonnet       | `high`  | 정형 학습 문서화(headless)                                                                                |
| Phase 3 `superpowers:finishing-a-development-branch` | Sonnet       | `high`  | 커밋·푸시·PR                                                                                              |
| `superpowers:systematic-debugging` (버그)            | Opus         | `xhigh` | 근본 원인 추적, 개방형 추론                                                                               |
| 면제 케이스 (타입/린터/리네임/트리비얼)              | Sonnet       | `high`  | 단순 작업, 판단 비중 낮음                                                                                 |

### 전환 메커니즘 (경계에서 수동 안내)

> **제약**: 메인 에이전트는 세션 도중 **스스로 모델을 바꿀 수 없다.** 모델·effort 전환은 사용자의 `/model`·`/effort` 입력 또는 `/clear` 후 새 세션에서만 가능하다.

운영 계약:

- 각 단계(특히 `/clear` 후 새 세션) 시작 시, 모델은 그 단계의 **권장 모델·effort를 사용자에게 announce**하고 현재 설정과 다르면 전환을 **안내한 뒤** 진행한다. 강제하지 않고 안내·확인만 한다. (모델이 자기 effort를 항상 조회할 수 있는 건 아니므로, "점검"보다 "announce + 안내"가 안전하다.)
- 파이프라인의 `/clear` 지점이 자연스러운 전환 경계다. Phase 1·2는 Opus xhigh로 연속이므로 그 사이엔 전환이 없다. Phase 2→2' 경계에서 Sonnet high로 내린다.
- **ce-code-review 예외**: Phase 2' 내부의 ce-code-review는 `/clear` 경계가 아니다. 따라서 **세션 모델을 바꾸지 않는다** — 세션은 Sonnet high를 유지한다(세션 중 `/model` 전환은 전체 히스토리 캐시 재로딩 비용이 커서, 가장 비싼 단계를 더 비싸게 만든다). ce-code-review는 6+ 리뷰어 **subagent**로 팬아웃되므로 "Opus xhigh"는 세션이 아니라 **리뷰어 레벨**을 뜻한다. 리뷰어를 Opus로 올리는 것은 subagent 모델 지정 영역이며(글로벌 '경계 수동 안내'와 별개로, 플러그인 frontmatter pin은 채택 안 함), 강제하지 않는다. 비용 우선이면 리뷰어가 세션 모델(Sonnet)을 상속하게 두고, 품질이 특히 중요한 변경에서만 리뷰어를 Opus로 운용한다.

현재 글로벌 디폴트(`~/.claude/settings.json`): `model: Opus`, `effortLevel: xhigh`. 따라서:

| 진입 단계                                           | 안내할 전환 명령                                                                                |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| Opus xhigh 단계 (brainstorming, ce-plan, debugging) | (디폴트와 동일 — 전환 불필요)                                                                   |
| ce-code-review (Phase 2' 내부)                      | (세션 전환 없음 — 세션 Sonnet 유지, 리뷰어 subagent만 Opus 권장. 위 "ce-code-review 예외" 참조) |
| Sonnet high 단계 (build·verify·compound·ship·면제)  | `/model sonnet` 그리고 `/effort high`                                                           |
| Sonnet 단계에서 Opus 단계로 복귀                    | `/model opus` 그리고 `/effort xhigh`                                                            |

참고: Sonnet 4.6은 `xhigh`를 지원하지 않으며 기본 effort가 이미 `high`다. 글로벌 디폴트가 `xhigh`이므로 Sonnet 전환 시 `/effort high`를 함께 안내해 의도를 명확히 한다.

---

## 95% confidence opener (Phase 1 첫 turn — 모델 발화)

brainstorming 스킬 진입 시 모델이 사용자에게 던지는 첫 질문 형태(spec §4.1과 동일):

> "지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95% 확신이 생길 때까지 질문을 던지겠습니다 — 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다."

운영 계약:

- brainstorming 체크리스트 3번(clarifying questions)을 95% confidence가 될 때까지 반복.
- 한 번에 한 질문 원칙 유지. 사용자의 첫 응답을 비판 없이 수용하지 않음.
- 명시되지 않은 엣지 케이스(실패 모드·데이터 결손·권한·동시성 등)를 능동 발굴.
- 95% 미만에서 설계 제시 단계로 넘어가지 않음.

**rigor-probe 렌즈 (제품성 작업일 때 — ce-brainstorm에서 흡수)**:

95% opener가 아무 방향으로나 흩어지지 않게, 사용자·가치 표면이 있는 작업(신규 기능·엔드포인트·behavior 변경)일 때는 다음 5종 렌즈로 질문을 도출한다:

- **evidence** — 말한 want가 아니라 실제로 한 행동(시간·비용·우회책)이 있나
- **specificity** — 구체적 수혜자는 누구이고 그에게 무엇이 바뀌나
- **counterfactual** — 지금은 어떻게 하나, 안 만들면 무엇이 바뀌나
- **attachment** — 같은 가치를 주는 최소 형태는 무엇인가
- **durability** — 가까운 변화에 이 가정이 견디나

비제품 작업(대규모 리팩토링·광범위 문서·툴링)에는 적용하지 않는다 — 압박할 '진짜 사용자 니즈'가 없어 제품형 probe가 헛돌기 때문. 이는 ce-brainstorm의 Product Pressure Test를 _도구 교체 없이_ 95% opener 위에 얹은 것이다 (브레인스토밍 도구는 superpowers 유지, 질문 방법론만 ce-brainstorm에서 흡수 — 근거는 spec §3 표).

---

## 트리거

### 풀 파이프라인 발동 (Plan Mode 트리거와 동일)

다음 중 하나 만족:

- 3+ 파일 변경
- 새 모듈·패턴·아키텍처 결정
- 새 의존성 추가
- public API 또는 데이터 스키마 변경
- 사용자 명시 요청 (`"제대로 설계해줘"`, `"plan 짜줘"` 등)

### 면제 (Phase 1·2 스킵, 직접 Phase 2'부터 — TDD도 면제) ▸ Sonnet · high

- 타입 어노테이션만 추가
- ruff 자동 픽스
- 단일 파일 리네임 (behavior 변경 없음)
- 코멘트/docstring 정리
- 의존성 버전만 올림
- 1줄~수십 줄의 명백한 리팩토링 (기존 테스트가 그대로 통과)

면제 케이스는 **Sonnet · high**로 처리한다(글로벌 디폴트 Opus xhigh로 진입했다면 `/model sonnet`·`/effort high` 안내). 면제 적용 시에도 변경 후 `pytest` 한 번은 돌린다. 면제 판단이 애매하면 `AskUserQuestion`으로 확인.

### 부분 발동

- README 광범위 업데이트 → Phase 1 [Opus·xhigh] + Phase 3 [Sonnet·high] (build 단계 없음)
- eval 결과 분석/회귀 → Phase 3의 `/ce-compound`만 [Sonnet·high] (artifacts/\*.csv 입력)

---

## 메모리 · 문서 4-tier

| Tier                  | 위치                                                       | 책임                                                                                                                                   | 변경 주체                                  |
| --------------------- | ---------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| 0. 글로벌 행동 규칙   | `~/.claude/CLAUDE.md`, `~/.claude/rules/`                  | 협업 원칙, 게이팅                                                                                                                      | **사용자 수동만**                          |
| 1. 글로벌 메타 메모리 | `~/.claude/projects/.../memory/`, `~/.claude/.remember/`   | user/feedback/project/reference, 세션 단위                                                                                             | 모델이 user/feedback 발화에 한해 자동 갱신 |
| 2. 프로젝트 의사결정  | `<proj>/docs/superpowers/specs/`, `<proj>/docs/plans/`     | spec, plan                                                                                                                             | 모델 작성, 사용자 승인 게이트              |
| 3. 프로젝트 학습 누적 | `<proj>/docs/solutions/`                                   | ce-compound 산출물 (**파일 콘텐츠는 한국어로 작성**, frontmatter 키·enum 값은 영문 유지) (write) + ce-learnings-researcher 조회 (read) | 모델 자동 (headless)                       |
| 4. 프로젝트 시각화    | `<proj>/graphify-out/`, `<proj>/docs/solutions/*.graph.md` | graphify 산출물                                                                                                                        | 사용자 또는 모델 호출 시                   |
| 5. 프로젝트 진행 추적 | `<proj>/TODO.md`                                           | 후속 작업 목록                                                                                                                         | 양쪽                                       |

**정책**:

- Tier 0/1로의 `/ce-compound` 자동 반영은 금지. Tier 3의 솔루션이 가치 있다고 판단되면 사용자가 손으로 Tier 0/1에 옮긴다.
- Tier 3는 write-only가 아니다. Phase 2의 `/ce-plan` 리서치 단계에서 `ce-learnings-researcher`가 docs/solutions/를 조회해 과거 학습을 plan에 반영한다 → compound 학습 루프가 닫힌다.
- ce-learnings-researcher 호출 게이트: `docs/solutions/`에 파일이 **3개 이상**일 때만 발동. 그 미만이면 검색 노이즈가 신호를 압도하므로 생략.

---

## 에러 / 엣지 케이스

| 상황                                       | 정책                                                                                    |
| ------------------------------------------ | --------------------------------------------------------------------------------------- |
| Plan Mode 안에서 ce-plan의 Write 차단됨    | 방식 2 (PostToolUse 훅) fallback. 결과를 spec §9 Open Questions에 기록 후 spec 갱신     |
| plannotator가 ExitPlanMode 가로채기 실패   | `/plannotator-annotate docs/plans/<file>` 수동 호출                                     |
| ce-work parallel subagent worktree 충돌    | ce-work 내장 정책 (abort → serial 재시도)                                               |
| ce-compound headless 잘못된 분류           | docs/solutions/는 git tracked, 사용자가 수동 정정·삭제                                  |
| ce-compound 토큰 초과                      | 입력 시 요약·헤더만 전달, RTK 압축 활용                                                 |
| docs/solutions/가 비어있거나 파일 2개 이하 | ce-learnings-researcher 호출 생략 — 신호 부족 상태의 조회는 노이즈를 plan에 주입할 위험 |
| TDD 면제 판단 애매                         | `AskUserQuestion`으로 사용자 확인                                                       |

---

## 변경 시 spec 동기화

본 문서를 갱신할 때는 spec(`docs/superpowers/specs/2026-05-19-compound-superpowers-hybrid-workflow.md`)도 함께 갱신해 1:1 정합을 유지한다. 단계명·도구명·트리거 조건이 두 문서에서 다르면 spec을 기준으로 본 문서를 정정한다.
