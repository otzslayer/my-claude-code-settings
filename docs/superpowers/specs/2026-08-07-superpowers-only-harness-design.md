# Superpowers 단독 하네스 전환 — 설계

- 작성일: 2026-08-07
- 대상 저장소: `~/.claude` (전역 설정)
- 성격: 삭제 중심 리팩터. 새 기능 추가 없음.

---

## 1. 배경과 목표

현재 하네스는 Superpowers와 Compound Engineering을 묶은 7단계 하이브리드 파이프라인이고, 그 정본이 `rules/hybrid-workflow.md`(9.8K)다. 이 문서는 매 세션 컨텍스트에 상주하며 다음 세 가지를 담고 있다.

1. CE 스킬(`ce-plan`·`ce-work`·`ce-doc-review`·`ce-code-review`)을 축으로 한 단계 정의
2. 과업 복잡도를 채점해 `effort`를 정하는 routing quick card
3. 그 근거를 담은 `skills/hybrid-workflow-reference/` 지연 로드 스킬 3파일

세 가지 모두 이번 전환으로 존재 이유가 사라진다.

**목표 상태**

- 워크플로우는 Superpowers 스킬만으로 구성한다. Compound Engineering에서는 `ce-compound` 하나만 파이프라인 끝에 남긴다.
- `brainstorming`의 95% confidence opener를 폐기한다. Superpowers `brainstorming`이 자체 인터뷰 루프(한 번에 한 질문, 체크리스트, 승인 게이트)를 이미 갖고 있어 opener가 중복이다.
- 모델·`effort`는 사용자가 `/model`·`/effort`로 직접 설정한다. 에이전트는 채점하지도, 전환을 제안하지도 않는다.
- 위 세 변경의 결과로 죽는 규칙 파일·참조 스킬·훅 case를 남김없이 정리하고, 살아 있는 규칙만 갈 곳을 찾아 옮긴다.

---

## 2. 새 파이프라인

```
Phase 1  brainstorming        → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
         /clear
Phase 2  writing-plans        → docs/superpowers/plans/YYYY-MM-DD-<feature>.md
         /clear   ← 강제. 계획 세션에서 인라인 구현 금지
Phase 3  subagent-driven-development
           ├ 태스크마다: 구현 서브에이전트 → 태스크 리뷰(spec 준수 + 코드 품질)
           └ 마지막: 전체 브랜치 리뷰 (requesting-code-review의 code-reviewer.md를 내부 dispatch)
         verification-before-completion
         /ce-compound mode:headless   → docs/solutions/
         finishing-a-development-branch
```

### 2.1 실행 스킬로 `subagent-driven-development`를 고른 이유

`executing-plans` SKILL.md는 자신을 서브에이전트가 없는 하네스용 폴백으로 규정하고, 서브에이전트를 쓸 수 있으면 `subagent-driven-development`(이하 SDD)를 쓰라고 명시한다. Claude Code는 그 "쓸 수 있는" 목록에 들어 있다. 이 설계는 업스트림 권고를 따른다.

토큰 비교를 실제로 해 보면 권고와 결론이 일치한다. 단가를 base input 대비 **cache read 0.1x · cache write 1.25x**, 세션 baseline 39.6k, 10태스크 = 총 50턴, 턴당 컨텍스트 증가 4k로 두면:

| | executing-plans (단일 세션) | SDD |
|---|---|---|
| baseline | 1회 write 50k | 1회 write + 19회 read ≈ 110k |
| 누적 prefix 재읽기 | 0.1 × 6,880k = **688k** | spawn마다 리셋 |
| 구현 | delta write 250k | 10 spawn × 5턴 ≈ 430k |
| 리뷰 | (없음) | 10 spawn × 3턴 ≈ 320k |
| **합계** | **≈ 988k** | **≈ 860k** |

핵심은 단일 세션의 지배항이 **688k의 누적 prefix 재읽기**라는 점이다. 매 턴이 그때까지 쌓인 컨텍스트 전체를 다시 읽으므로 턴 수에 대해 O(N²)로 늘어난다. SDD는 spawn마다 컨텍스트가 리셋되므로 O(N)이다. 서브에이전트 baseline이 spawn마다 통째로 청구된다는 통념은 사실이 아니다 — Claude Code는 툴 스펙을 캐시에 로드하고 서브에이전트 시스템 프롬프트를 안정적인 prefix baseline으로 priming하므로, spawn 2~N은 baseline을 cache read로 낸다.

두 곡선이 O(N²) 대 O(N)이므로 교차점이 존재한다. 같은 가정에서 3태스크(15턴)면 executing-plans ≈ 226k 대 SDD ≈ 286k로 단일 세션이 싸고, 교차점은 대략 **5~7태스크** 부근이다. 그럼에도 SDD를 단일 기본값으로 삼는 이유는 두 가지다. 첫째, 비용이 실제로 문제가 되는 구간은 큰 계획 쪽이고 거기서 SDD가 이긴다. 둘째, SDD는 태스크마다 spec 준수·코드 품질 리뷰를 붙이고 마지막에 전체 브랜치 리뷰를 돌리는데, `executing-plans`(64줄, "계획 읽고 → 실행 → 보고"가 전부)에는 그런 장치가 없다. 작은 계획에서 잃는 60k는 이 품질 장치의 값으로 지불할 만하다.

위 숫자의 턴당 4k 증가·태스크당 5턴·리뷰어 diff 15k는 가정이다. 다만 결론을 만드는 것은 절대값이 아니라 O(N²) 대 O(N)이라는 형태이고, 그 형태는 가정에 흔들리지 않는다.

### 2.1.1 SDD의 종료 단계를 가로채야 한다

SDD는 전체 브랜치 리뷰가 깨끗해지면 **스스로 `finishing-a-development-branch`를 호출하며 끝난다.** 그대로 두면 이 설계의 `verification-before-completion`과 `/ce-compound`가 건너뛰어진다. `hooks/workflow-stage-inject.sh`의 `*subagent-driven-development` case가 이 지점을 가로채 순서를 바로잡는다(§3.5).

또한 SDD가 최종 리뷰에 `requesting-code-review`의 `code-reviewer.md`를 내부적으로 dispatch하므로, `requesting-code-review`를 파이프라인의 **별도 단계로 두지 않는다.** CLAUDE.md 스킬 표에는 계획 실행과 무관한 단독 코드 리뷰 요청용으로만 남긴다.

### 2.2 `/clear` 강제 경계를 유지하는 이유

`writing-plans`가 계획 파일을 쓰면 그 세션을 종료한다. 계획 과정에서 쌓인 탐색 컨텍스트(버려진 선택지, 중간 검색 결과, 폐기된 가설)를 구현 세션으로 끌고 가지 않기 위해서다. 토큰 측면에서도 유리하고, 구현 세션이 계획 파일만을 단일 입력으로 삼게 만들어 계획의 품질 결함이 드러나게 한다.

SDD의 description은 "in the current session"이라 이 경계와 충돌해 보이지만 그렇지 않다. 그 문구는 SDD의 **코디네이터**가 별도 세션을 요구하지 않는다는 뜻이고, 여기서 말하는 경계는 **계획 세션과 구현 세션 사이**다. `/clear` 후 새 세션에서 SDD를 코디네이터로 띄우면 둘 다 성립한다.

---

## 3. 파일별 변경

### 3.1 삭제

| 경로 | 사유 |
|---|---|
| `rules/hybrid-workflow.md` | 전체가 CE 파이프라인 + effort 채점. 생존 규칙은 §3.3·§3.4로 이전 |
| `skills/hybrid-workflow-reference/` | `scoring.md`·`units.md`는 effort 수동화로 사망, `brainstorming.md`(5렌즈)는 Superpowers 자체 질문 루프와 중복 |

`.gitignore`의 `!/skills/hybrid-workflow-reference/` opt-in 줄도 함께 제거한다(줄 번호가 아니라 내용으로 찾을 것).

`docs/superpowers/plans/`는 `.gitignore`상 이미 무시 대상이다(`/docs/superpowers/*` 이후 `specs/`만 opt-in). 계획 파일은 생성물이므로 이 상태가 맞고, `.gitignore` 추가 변경은 필요 없다.

### 3.2 `rules/hybrid-workflow.md` 섹션별 처분

| 섹션 | 내용 | 처분 |
|---|---|---|
| §1 | 7단계 파이프라인 + Phase 2 note | CLAUDE.md 스킬 표로 흡수(§3.3) |
| §3–§5 | effort 채점표·밴드·리뷰어 dispatch | 삭제 |
| §6 | 유닛 분량·직렬 서브에이전트 | 삭제 (`writing-plans`가 자체 유닛 가이드 보유) |
| §7 | 95% confidence opener + 5렌즈 포인터 | 삭제 |
| §8 | 전면 활성화 트리거 + 면제 목록 | CLAUDE.md Planning Trigger로 흡수(§3.3) |
| §9 | 메모리 tier 0/1 자동 기록 금지 | `rules/boundaries.md` Never로 이전(§3.4) |
| §10 | 에러·엣지 케이스 표 5행 | 4행은 CE 전용이라 삭제. "TDD 면제 판단이 애매하면 `AskUserQuestion`으로 확인" 1행만 CLAUDE.md Planning Trigger로 흡수 |

### 3.3 `CLAUDE.md`

**변경**

1. **L16–17 `using-superpowers` 자동 주입 문단** — 한 줄로 압축한다. 구현 세부(훅 파일명, `<SUBAGENT-STOP>` 설명)는 뺀다. 다만 "명시 재호출 금지"라는 결론 자체는 자동 주입되는 본문에 없으므로 반드시 남긴다.

2. **High-Priority Workflow Skills 표** — 재작성한다. 새 행 구성:

   | Trigger | Skill |
   |---|---|
   | 새 기능 / 컴포넌트 / 동작 변경 | `superpowers:brainstorming` → spec |
   | 다단계 구현 과업 | `superpowers:writing-plans` → plan, 이후 `/clear` |
   | 계획 실행 | `superpowers:subagent-driven-development` |
   | 버그 · 실패하는 테스트 | `superpowers:systematic-debugging` |
   | 구현 작업 | `superpowers:test-driven-development` (트리비얼 면제) |
   | 코드 리뷰 (계획 실행과 무관한 단독 요청) | `superpowers:requesting-code-review` |
   | 완료 선언 직전 | `superpowers:verification-before-completion` |
   | 학습 누적 (작업 완료 후) | `/ce-compound mode:headless` |
   | 커밋 · 푸시 · PR | `superpowers:finishing-a-development-branch` |
   | Python(`.py`) 작성·수정 | `python-coding-style` |
   | 새 Python 프로젝트 / 디렉터리 레이아웃 | `python-architecture` |

   표 아래 "Model·effort는 과업 복잡도 채점으로 정해진다"는 문장을 제거한다.

3. **Model · effort policy 문단(L37)** — 통째로 삭제하고 한 줄로 대체한다: 모델과 `effort`는 사용자가 `/model`·`/effort`로 직접 설정한다. 에이전트는 채점하지 않고 전환을 제안하지도 않는다.

4. **"Plan Mode (Shift+Tab)" 섹션 → "Planning Trigger"로 개명·재작성**
   - 트리거 목록(3+ 파일, 아키텍처 결정, 새 의존성, 공개 API·스키마 변경, 사용자 명시 요청)은 유지한다. 여기에 §8의 면제 목록(타입 어노테이션만, ruff 자동수정, 동작 변경 없는 단일 파일 리네임, 주석·독스트링 정리, 의존성 버전 범프, 기존 테스트가 그대로 통과하는 수십 줄 규모의 명백한 리팩터)을 병합한다.
   - §10의 생존 1행("면제 판단이 애매하면 `AskUserQuestion`으로 확인")을 여기에 넣는다.
   - `ce-plan` carve-out 문단(L79)은 삭제한다. `ce-plan`이 사라지므로 근거 자체가 없다.
   - Plan Persistence(L81)는 `writing-plans` 기준으로 재작성한다: `writing-plans` → `docs/superpowers/plans/` → `/clear` → `subagent-driven-development`. "같은 세션에서 인라인 구현 금지"는 유지한다.
   - Plan Mode(Shift+Tab) 자체는 "써도 되지만 파이프라인 단계는 아니다" 한 줄로 격하한다.

**유지 (변경 없음)**

Instruction Priority · Core Principles · Scope Clarification · When Stuck · Before Declaring Done · Rules Directory · TODO Management · RTK · CodeGraph 마커 블록 · graphify 섹션.

CodeGraph와 graphify 섹션은 각 도구 설치 시 자동 생성되는 블록이므로 손대지 않는다. `rules/boundaries.md` Tool Usage와 서술이 겹치지만, 자동 생성물을 지우면 재설치 때 되살아나 관리 비용만 늘어난다.

### 3.4 `rules/boundaries.md`

1. **Never 티어에 메모리 경계 추가** — `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/projects/.../memory/`(Tier 0/1)에 자동으로 기록하지 않는다. `/ce-compound`는 `docs/solutions/`(Tier 3)만 쓰고, 승격은 사용자가 수동으로 한다.

2. **Subagent dispatch 불릿 수정** — `hybrid-workflow.md`의 routing quick card 참조를 제거한다. 남는 사실만 유지한다: `Agent` 툴은 `model`만 받고 `effort`는 dispatch 세션에서 상속된다. `Workflow`의 `agent()`는 `model`·`effort` 둘 다 받는다.

### 3.5 `hooks/workflow-stage-inject.sh`

전면 재작성한다. 기존 9개 case 중 5개(`brainstorming`·`ce-plan`·`ce-doc-review`·`ce-work`·`ce-code-review`)가 죽고, 남는 4개도 effort 밴드 문구를 들어내야 해서 부분 수정보다 새로 쓰는 편이 명확하다.

새 case 구성:

| case | 주입 내용 |
|---|---|
| `*writing-plans` | 계획 본문 산문은 한국어. 계획 파일 Write 후 인라인 구현 금지 — 중단하고 `/clear`, 새 세션에서 `subagent-driven-development` |
| `*subagent-driven-development` | **종료 단계 가로채기**: 전체 브랜치 리뷰가 깨끗해져도 `finishing-a-development-branch`로 바로 가지 말 것. `verification-before-completion` → `/ce-compound mode:headless` → `finishing-a-development-branch` 순서를 지킬 것 |
| `*test-driven-development` | RED → GREEN → REFACTOR, 트리비얼 면제 |
| `*requesting-code-review` | 리뷰·수정 완료 후 `verification-before-completion`으로 진행 |
| `*verification-before-completion` | `uv run ty check` · `ruff check --fix` · `ruff format` · `pytest -v`를 실제 실행하고 그 출력으로 확인한 뒤에만 완료 선언. 통과 후 `ce-compound mode:headless` |
| `*ce-compound` | `mode:headless`, `docs/solutions/`만 생성(콘텐츠 한국어, frontmatter 키·enum 영문). Tier 0/1 자동 반영 금지. 이후 `finishing-a-development-branch` |
| `*finishing-a-development-branch` | 커밋 메시지는 한국어 포맷 |
| `*systematic-debugging` | 수정 전 재현 테스트 먼저. 같은 접근 3회 실패 시 중단·대안 |

`*brainstorming` case는 만들지 않는다. 95% opener가 이 case의 유일한 내용이었고 그것이 폐기 대상이다.

파일 상단 주석과 `jq` 파싱 근거 주석(BSD grep·pyenv shim 회피)은 여전히 유효하므로 새 파일에도 유지한다. `emit()` 헬퍼의 "본문에 큰따옴표 금지" 제약도 유지한다.

### 3.6 `settings.json`

1. **한국어 산문 강제 훅 경로 수정** — 현재 정규식이 `docs/plans/.*\.md$`라 새 파이프라인에서는 절대 발동하지 않는다. `docs/superpowers/(plans|specs)/.*\.md$`로 바꾼다. `brainstorming`이 쓰는 spec도 산문이므로 같은 이유로 커버한다. 주입 문구 안의 "계획 파일" 표현도 계획·스펙 양쪽을 가리키도록 고친다.

2. **`PostToolUse:ExitPlanMode` 훅 항목 삭제** — Superpowers 파이프라인은 Plan Mode를 쓰지 않는다. `writing-plans`가 `Write`로 계획 파일을 직접 쓰며 `ExitPlanMode`를 호출하지 않고, Superpowers 전체에서 Plan Mode 언급은 `using-superpowers`의 "Plan Mode 진입 전 brainstorming 먼저" 한 줄뿐이다. 훅 본문이 참조하는 Plannotator `PermissionRequest` 게이트는 `settings.json`에 애초에 설정된 적이 없어 이미 죽은 서술이다. Plannotator가 필요하면 `plannotator annotate <path>`를 수동 실행한다.

3. **`skillOverrides`에 CE 스킬 off 추가** — `ce-compound`를 제외한 나머지를 끈다.

   `ce-babysit-pr` · `ce-brainstorm` · `ce-code-review` · `ce-commit` · `ce-commit-push-pr` · `ce-compound-refresh` · `ce-debug` · `ce-doc-review` · `ce-explain` · `ce-handoff` · `ce-ideate` · `ce-optimize` · `ce-plan` · `ce-pov` · `ce-proof` · `ce-resolve-pr-feedback` · `ce-riffrec-feedback-analysis` · `ce-simplify-code` · `ce-strategy` · `ce-test-browser` · `ce-work` · `ce-worktree` · `lfg` (총 23개)

   **미검증 리스크 — 이 작업 전체의 유일한 차단 요소다.** 현재 `skillOverrides` 항목은 전부 사용자 스킬(`~/.claude/skills/` 디렉터리명, 예: `"python-core": "off"`)이다. 플러그인 스킬은 다른 네임스페이스이므로, 키 형식 이전에 **`skillOverrides`가 플러그인 스킬을 대상으로 삼기는 하는지**가 먼저 미확인 상태다.

   검증 절차 (§4의 1단계에서 **가장 먼저** 수행):

   1. `"ce-plan": "off"` 하나만 넣는다.
   2. 새 세션을 열어 `/context`의 Skills → Plugin (compound-engineering) 목록을 본다.
   3. 사라졌으면 이 형식으로 나머지 22개를 적용한다.
   4. 남아 있으면 `"compound-engineering:ce-plan"` 형식으로 바꿔 2–3을 반복한다.
   5. 두 형식 모두 실패하면 `skillOverrides`가 플러그인 스킬을 커버하지 않는 것이다.

   5번일 때의 **기본 대안: 플러그인을 그대로 켜 둔 채 CLAUDE.md 스킬 표만으로 라우팅한다.** 현상 유지에서 표의 CE 행만 빠진 상태이므로 위험이 0이고, 비용은 스킬 리스팅 약 2.4k 토큰뿐이다. 플러그인 자체를 끄는 선택지(= `ce-compound` 포기 또는 수동 복사)는 이 대안보다 나쁘므로 채택하지 않는다. 5번에 도달하면 이 대안을 적용한 사실을 사용자에게 보고한다.

`enabledPlugins`의 `compound-engineering@compound-engineering-plugin`은 **유지한다**. `ce-compound`를 쓰려면 플러그인이 설치되어 있어야 한다.

### 3.7 `README.md`

워크플로우 관련 전 구간을 재작성한다. 대상:

- L5 메인 하네스 설명 (`Compound + Superpowers 하이브리드` → Superpowers 단독)
- L113 · L141 · L151 손-작성 스킬 4종 목록 → `hybrid-workflow-reference` 제거해 3종으로
- L127 `rules/` 파일 5종 → 4종
- L128 `skills/hybrid-workflow-reference/` 행 삭제
- L148 플러그인 스킬 복원 설명에서 compound-engineering 역할 수정
- L158 · L167 · L173 지연 로드 구조 설명 전체 삭제
- L185–187 파이프라인 다이어그램 재작성
- L190 · L213 effort 채점 서술 삭제
- L223 · L227 · L230 · L234 ce-plan carve-out / Plan Mode 흐름 설명 삭제 또는 Planning Trigger 기준 재작성
- L242 플러그인 표에서 compound-engineering 설명 수정 (`ce-compound`만 사용)
- L285 메모리 seed 주석에서 `rules/hybrid-workflow.md` 참조 제거

---

## 4. 실행 순서

의존 관계상 아래 순서를 따른다. 문서(README)는 코드·설정 변경이 확정된 뒤에 맞춰야 어긋나지 않는다.

1. `settings.json` — **§3.6의 `skillOverrides` 검증 절차를 가장 먼저 수행한다**(새 세션 `/context` 확인이 필요하므로 이 단계에서 한 번 끊긴다) → 결과에 따라 CE 스킬 23개 off 또는 기본 대안 적용, 이어서 한국어 훅 경로 수정, `ExitPlanMode` 훅 삭제
2. `hooks/workflow-stage-inject.sh` 재작성
3. `CLAUDE.md` 재작성
4. `rules/boundaries.md` 수정
5. `rules/hybrid-workflow.md` 삭제 · `skills/hybrid-workflow-reference/` 삭제 · `.gitignore` opt-in 제거
6. `README.md` 재작성
7. 잔여 참조 검증 (§5)

---

## 5. 검증

이 저장소에는 실행 가능한 테스트 스위트가 없다. 설정·문서 저장소이므로 검증은 정적 확인으로 한다.

- [ ] `grep -rn "hybrid-workflow\|ce-plan\|ce-work\|ce-doc-review\|ce-code-review" CLAUDE.md rules/ hooks/ README.md .gitignore` 결과가 비어 있을 것. `settings.json`은 `skillOverrides`에 이 이름들이 **off 대상 키로 의도적으로 남으므로** 이 검사에서 제외한다 — 대신 `jq '.skillOverrides' settings.json`으로 23개 키가 모두 `"off"`인지 확인한다
- [ ] `grep -rn "docs/plans" settings.json hooks/ CLAUDE.md` 결과가 비어 있을 것
- [ ] `jq . settings.json` 통과 (JSON 유효)
- [ ] `bash -n hooks/workflow-stage-inject.sh` 통과 (문법)
- [ ] 훅 단위 확인: `echo '{"tool_input":{"skill":"superpowers:writing-plans"}}' | bash hooks/workflow-stage-inject.sh` 가 유효한 JSON을 출력할 것. 등록되지 않은 스킬명은 무출력·exit 0일 것
- [ ] 새 세션에서 `/context`로 `rules/` 4종만 로드되고 CE 스킬이 목록에서 사라졌는지 확인
- [ ] `skillOverrides` 키 형식이 실제로 먹었는지 확인 (§3.6 미검증 리스크)

---

## 6. 명시적 비목표

- Superpowers·Plannotator·CodeGraph·RTK·graphify 자체 설정은 건드리지 않는다.
- `rules/` 나머지 4개 파일(`git-workflow`·`karpathy-principles`·`security`, 그리고 `boundaries`의 §3.4 외 부분)의 내용을 압축하지 않는다. 이번 작업은 CE 제거지 사용자 정책 압축이 아니다.
- `~/.claude/plugins/` 아래 플러그인 스킬 본문을 수정하지 않는다. 업데이트 시 덮어써지는 머신 상태다.
- 프로젝트별 `docs/solutions/` 기존 내용은 손대지 않는다.
