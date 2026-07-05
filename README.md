# my-claude-code-settings

`~/.claude`를 git으로 추적하는 개인 설정 저장소. 개인 멀티머신 백업과 공개를 동시에 지원하도록 설계됐다.

**메인 하네스**: Compound + Superpowers 하이브리드 워크플로우 (`rules/hybrid-workflow.md`)

**발표자료**: [`PRESENTATION.pdf`](PRESENTATION.pdf) — 이 저장소가 추구하는 하이브리드 워크플로우 설명 자료

---

## 설치

### 자동 설치 (권장)

```bash
git clone https://github.com/otzslayer/my-claude-code-settings.git ~/.claude
bash ~/.claude/scripts/install.sh
```

`scripts/install.sh`는 gum TUI 기반 인터랙티브 설치기다. macOS와 WSL2를 지원하며, gum이 없으면 plain read 폴백으로 동작한다.

**설치기가 처리하는 항목**:
- rtk (token optimizer) + jq (rtk-rewrite 훅의 하드 의존) + `rtk init -g` (RTK.md 생성 — 순서 보장)
- codegraph (symbol-level code intelligence) — `~/.claude.json`에 MCP 자동 등록 (idempotent)
- graphify (knowledge graph CLI)
- slides-grab (npm 패키지)
- plannotator (Plan Mode 브라우저 리뷰 UI 바이너리 — plannotator 플러그인 prerequisite)
- 메모리 seed 동기화 (`memory-templates/`)
- `settings.json` skip-worktree 적용 (permissions 재유입 방지)

> **skip-worktree**: Claude 세션 중 grant가 `settings.json`에 재기입되어 `git status`가 dirty가 되는 현상을 방지한다. `install.sh`가 자동 실행하나, clone 후 재실행이 필요하다. 해제: `git update-index --no-skip-worktree settings.json`

설치 후 **Claude Code를 재시작**하면 `settings.json`의 `enabledPlugins`가 읽혀 플러그인이 자동 설치된다.

---

### 수동 설치

> **중요**: 아래 순서를 반드시 지킬 것. `rtk init -g`를 먼저 실행하지 않으면 CLAUDE.md의 `@RTK.md` import가 깨진다.

#### 1단계: RTK 설치 (최우선)

```bash
# RTK (token optimizer) 설치 — brew tap이 없다면 GitHub Releases에서 직접 설치
brew install reachingforthejack/rtk/rtk   # 또는 릴리즈 바이너리 직접 설치

# jq — rtk-rewrite 훅의 하드 의존 (없으면 명령 재작성 훅이 조용히 비활성화됨)
brew install jq   # Linux/WSL2: sudo apt-get install -y jq

# RTK.md 글로벌 초기화 — 이 단계 없이는 CLAUDE.md @RTK.md import가 깨짐
rtk init -g

# 확인
rtk --version
```

#### 2단계: 나머지 툴 설치

```bash
# CodeGraph (symbol-level code intelligence)
# 공식 설치 가이드 참조: https://github.com/...

# graphify (knowledge graph CLI)
uv tool install graphifyy

# slides-grab (npm 패키지, Codex용)
npm install -g slides-grab

# plannotator (Plan Mode 브라우저 리뷰 UI 바이너리)
curl -fsSL https://plannotator.ai/install.sh | bash
```

#### 3단계: 저장소 복제

```bash
git clone https://github.com/otzslayer/my-claude-code-settings.git ~/.claude
cd ~/.claude
```

#### 4단계: skip-worktree 적용

```bash
git update-index --skip-worktree settings.json
```

#### 5단계: Claude Code 첫 실행

```bash
claude
```

Claude Code가 `settings.json`의 `enabledPlugins`와 `extraKnownMarketplaces`를 읽어 플러그인을 자동 설치한다. 플러그인 캐시(`plugins/cache/`)가 생성된 뒤 statusLine이 점등된다.

> **참고**: skills/는 git에서 추적하지 않는다. 플러그인 스킬은 Claude Code가 자동 설치하고, npm/CLI 스킬(slides-grab*, graphify)은 위 2단계에서 직접 설치해야 한다.

---

## Tracking 정책

`.gitignore`는 **provenance allowlist** 방식을 사용한다: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in.

### 추적하는 것

| 항목 | 이유 |
|------|------|
| `CLAUDE.md` | 메인 개발 가이드라인 |
| `settings.json` | 포터블화된 플러그인·훅 설정 |
| `rules/` | 행동 규칙 파일 4종 |
| `memory-templates/` | 세션 간 메모리 seed |
| `hooks/*.sh` | rtk-hook, rtk-rewrite, workflow-stage-inject, graphify-install-check |
| `scripts/sync-memory-templates.sh` | 메모리 템플릿 동기화 |
| `.gitignore`, `.gitattributes`, `README.md` | 저장소 메타 |
| `PRESENTATION.pdf` | 하이브리드 워크플로우 발표자료 |

### 추적하지 않는 것 (기본 무시)

- `plugins/` — Claude Code가 자동 관리, 버전 핀 불필요
- `skills/` — 플러그인·npm·CLI가 재설치 가능. 커스텀 수정은 업스트림 회귀 또는 별도 보존
- `memory/` — 머신별 세션 메모리, 민감 정보 포함 가능
- `node_modules/`, `security/`, `daemon/`, `sessions/` 등 런타임 산출물
- `settings.local.json` — 머신 로컬 override

### 스킬 복원 안내

- **플러그인 스킬** (compound-engineering, superpowers, plannotator 등): Claude Code 재실행 시 자동 복원
- **npm 스킬** (slides-grab, slides-grab-design, slides-grab-export, slides-grab-plan): `npm install -g slides-grab`
- **CLI 스킬** (graphify): `uv tool install graphifyy`
- **순수 bespoke 스킬** (peon-ping-*, plannotator-compound 등): 별도 보존 필요 (현재 미추적)

---

## 메인 하네스: Hybrid Workflow

`rules/hybrid-workflow.md`가 정식 운영 가이드다. 요약:

```
Phase 1: Spec    superpowers:brainstorming → docs/superpowers/specs/
Phase 2: Plan    non-plan-mode: /ce-plan → docs/plans/  (자동 ce-doc-review → EnterPlanMode→ExitPlanMode 브라켓으로 Plannotator 하드 게이트 재발동)
Phase 2': Build  /ce-work <plan-path>
Phase 3: Ship    verify → /ce-compound → commit+PR
```

각 단계의 model·effort는 더 이상 단계별 고정값이 아니라, **과업 복잡도를 채점**해 정해진다(`rules/hybrid-workflow.md` §3 "Complexity scoring"이 정본).

### model·effort는 어떻게 정해지나 (복잡도 채점)

과업마다 **기저점**(인지 성격)에 **가산 신호**(범위)를 더해 0–10점을 매기고, 점수 구간(밴드)이 model·effort를 정한다.

| 기저점 | 예 | 점수 |
|---|---|---|
| 기계적 실행 | 빌드·검증·리네임·포맷 | 1 |
| 표준 구현 | 잘 정의된 기능·바운드된 버그 | 3 |
| 개방형 추론 | 설계·브레인스토밍·근본원인 디버깅 | 5 |

여기에 파일 수(+1~+3), 새 모듈/아키텍처 결정(+2), 새 의존성(+1), API·스키마 변경(+2), 동시성/보안/마이그레이션 같은 교차 관심사(+2), 실질적 모호성(+2)이 해당할 때마다 더해진다(상한 10).

| 점수 | 밴드 | model | effort | 예시 |
|---|---|---|---|---|
| 0–2 | 사소·기계적 | opus-4.8 | low | "테스트 통과 확인만" |
| 3–5 | 표준 | opus-4.8 | medium | "새 엔드포인트 하나 추가, 파일 3개" |
| 6–7 | 조금 어려움 | opus-4.8 | high | "새 의존성 도입 + 데이터 스키마 변경" |
| 8–10 | 복잡함 | opus-4.8 | xhigh | "새 아키텍처 결정 + API 스키마 변경 + 교차 관심사" |

예: "표준 구현(base 3) + 파일 3–5개(+2) + 동시성 얽힘(+2)" = 7점 → **opus·high**를 announce하고 현재 세션과 다르면 `/model`·`/effort` 전환을 안내한다(강제 아님).

**단, Build 단계(ce-work)는 예외다**: 완성된 계획을 실행하는 build 작업은 계획이 이미 판단을 front-load했으므로 base 1(기계적 실행)로 채점하고, 계획-시점 가산 신호(파일 수·새 모듈·API/스키마 변경)를 **다시 세지 않는다** — 그래서 파일이 아무리 많아도 기본값은 **opus·medium**이다 — 모든 밴드가 opus인 지금, 이 예외는 모델 등급을 낮추는 게 아니라 **effort를 medium으로 캡**한다(계획이 아무리 커도 build를 high/xhigh로 올리지 않음). 파일 수는 유닛 분량으로 처리한다. build가 opus로 올라가는 건 오직 **반응적**일 때뿐이다: 실행이 계획이 예견 못 한 것을 드러낼 때 — RED→GREEN 정체가 개방형 근본원인 디버깅으로 전환되거나(그 서브태스크는 base-5 디버깅으로 재채점), 되돌리기 어려운 변경에서 테스트/타입체크가 실패할 때(§4 re-run 게이트). 계획-시점 범위로는 선불 승격하지 않는다.

**fable-5**는 점수로는 절대 도달하지 않는다 — 여러 서브시스템을 넘나드는 지속적 설계·구현이나 긴 agentic 체인처럼 "진짜로 길고 복잡한" 과업임을 명시적으로 판단했을 때만 옵트인한다(점수 라우팅 상한은 opus·xhigh). haiku는 이 파이프라인에서 쓰지 않는다.

**메커니즘 제약**: 메인 에이전트는 세션 도중 자기 모델을 못 바꾼다 — `/model`·`/effort`로 announce & 전환 안내만 가능. 점수 기반 밴드가 전부 opus인 지금 `/model`은 fable long-horizon flag가 켜질 때(혹은 세션이 opus가 아닐 때)만 바뀌고, 밴드별 변화는 사실상 `/effort`만 담당한다. 서브에이전트 디스패치는 두 갈래다: `Agent` 툴은 `model`만 지정 가능(effort는 디스패치 세션에서 상속), `Workflow`의 `agent()`는 `model`+`effort` 둘 다 개별 지정 가능(완전 동적).

**리뷰어 분기**: 코드/문서 리뷰는 본질적으로 개방형 적대적 추론(base 5)이다. 원래는 가장 중요한 판정만 opus(`ce-code-review`의 correctness·security·adversarial, `ce-doc-review`의 adversarial·security-lens)로 올리고 나머지는 sonnet으로 돌렸으나, **현재는 sonnet이 라우팅에서 제외되어 전 리뷰어가 `model=opus`로 통일**되어 있다(아래 "Sonnet-5 제외" 참고). 이 opus-vs-sonnet 분기는 Sonnet 재도입 시 복원할 기준으로 `hybrid-workflow.md` §5에 기록되어 있다.

세션 resting 기본값(`settings.json`)은 `effortLevel: high`다 — `xhigh`는 8–10 밴드에서 과업별로만 도달하며 상시 기본값이 아니다.

**Sonnet-5 제외 (비용 역전, 한시적)**: per-token 단가만 보면 Sonnet-5가 가장 싸지만, 이 파이프라인의 다단계 agentic 작업에서는 토큰·반복이 3~4배로 불어나 **실효 비용이 Opus 4.8 이상으로 뒤집히고 정확도는 낮다**. 근거 — BrowseComp에서 Opus·low($5/67.7%)가 Sonnet·high($7/64.8%)를 비용·정확도 모두에서 앞서고, Artificial Analysis 인덱스 전체 실행 비용은 Opus 4.8 max $3,753 < Sonnet 5 max $6,015이며, 실측 agentic 태스크에서 Opus 4.8 단독은 70회/$7.07인 반면 Sonnet 5 단독은 309회/$20.95였다(가장 싼 모델이 최종 비용은 가장 큼). 그래서 0–5 밴드와 §5 비적대 리뷰어까지 전부 Opus 4.8로 통일한다. **추후 Sonnet 비용이 정상화되면** — 재벤치마크에서 해당 밴드의 검증된-결과당(cost-per-verified-outcome) 비용이 다시 Opus 아래로 내려오면 — 저비용 밴드(0–5)와 비적대 리뷰어에 Sonnet을 언제든 재도입한다. haiku는 이 파이프라인에서 쓰지 않는다.

> 참고:
> - <https://www.reddit.com/r/ClaudeAI/comments/1ujx3rw/sonnet_5_is_worse_than_opus_at_the_same_price_at/>
> - <https://www.reddit.com/r/theprimeagen/comments/1ukscqq/the_new_claude_sonnet_5_is_more_costly_than_fable/>
> - <https://devbrothers.ai/blog/advisor-%EC%A0%84%EB%9E%B5-claude-fable-5%EC%97%90%EA%B2%8C-%EC%9D%BC%EC%9D%84-%EC%8B%9C%ED%82%A4%EC%A7%80-%EB%A7%90%EA%B3%A0-%EC%8B%9C%ED%82%A4%EB%8A%94-%EC%97%AD%ED%95%A0%EC%9D%84-%EC%8B%9C%EC%BC%9C%EB%9D%BC/>

### Plan 단계 흐름 (Plan Mode ↔ Plannotator 디커플링)

`/ce-plan`의 본작업(계획 파일 작성, ce-doc-review의 자동 수정)은 Plan Mode 밖(non-plan-mode)에서 실행된다 — Plan Mode가 파일 쓰기와 자동 수정을 막기 때문이다. 대신 계획이 확정된 뒤, **편집 없이 `EnterPlanMode` → 곧바로 `ExitPlanMode`**를 호출하는 "브라켓"으로 Plannotator의 승인 게이트를 다시 건다 — 이 게이트는 브라우저에서 승인하기 전까지 `/clear`를 막는 하드 게이트라서, non-plan-mode로 옮겨도 사람 리뷰가 사라지지 않는다.

```
non-plan-mode → /ce-plan (계획 작성) → 자동 ce-doc-review(리뷰어 model 분기)
  → EnterPlanMode→ExitPlanMode 브라켓 → Plannotator 승인(브라우저) → /clear
```

일반적인 "복잡한 작업 전에는 Plan Mode로 먼저 분석한다"는 규율(CLAUDE.md)은 그대로 유지된다 — 위 흐름은 `/ce-plan` 자체의 실행 방식에 대한 예외(carve-out)일 뿐이다.

### 의존 플러그인

| 플러그인 | 역할 |
|---------|------|
| `compound-engineering@compound-engineering-plugin` | ce-plan, ce-work, ce-code-review 등 메인 workflow |
| `superpowers@claude-plugins-official` | brainstorming, TDD, debugging 등 process skills |
| `plannotator@plannotator` | Plan Mode 승인 게이트 (browser UI) |
| `context7@claude-plugins-official` | 라이브러리 문서 실시간 조회 |
| `skill-creator@claude-plugins-official` | 스킬 생성·최적화 |
| `claude-md-management@claude-plugins-official` | CLAUDE.md 감사·개선 |
| `code-simplifier@claude-plugins-official` | 코드 단순화 |
| `commit-commands@claude-plugins-official` | 커밋·PR 워크플로우 |
| `claude-dashboard@claude-dashboard` | statusLine |
| `claude-hud@claude-hud` | 상태 HUD |

### 의존 MCP 서버

- `codegraph` — symbol-level code intelligence (`.codegraph/` 인덱스). `install.sh`가 `~/.claude.json`에 자동 등록
- `computer-use` — 스크린샷·GUI 자동화 (수동 등록)
- `sequential-thinking` — 다단계 추론 (수동 등록)

---

## 메모리 Seed

`memory-templates/`는 세션 메모리의 seed용 템플릿 디렉토리다. git으로 추적된다.

라이브 메모리 중 보존하고 싶은 것은 `memory-templates/`에 파일을 추가하면 `scripts/sync-memory-templates.sh`로 동기화할 수 있다.

```bash
# 메모리 템플릿 동기화
bash scripts/sync-memory-templates.sh
```

> 현재 seed: `feedback_hybrid_workflow.md` — hybrid workflow 운영 규칙 피드백

---

## settings.json 포터블화 정책

- 절대경로 없음 — 모든 경로는 `$HOME` 기반
- statusLine은 버전 핀 없이 glob으로 최신 버전 자동 사용
- peon-ping 훅 없음 (머신 로컬 취향, 공개 제외)
- permissions 없음 (Claude가 grant 시 재기입하므로 초기 커밋만 깨끗하면 됨)
