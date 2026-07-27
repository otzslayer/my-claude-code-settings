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
- plannotator (계획 파일 브라우저 리뷰 UI 바이너리 — plannotator 플러그인 prerequisite)
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

# plannotator (계획 파일 브라우저 리뷰 UI 바이너리)
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

> **참고**: `skills/`는 원칙적으로 추적하지 않는다(`hybrid-workflow-reference` 하나만 예외). 플러그인 스킬은 Claude Code가 자동 설치하고, npm/CLI 스킬(slides-grab*, graphify)은 위 2단계에서 직접 설치해야 한다.

---

## Tracking 정책

`.gitignore`는 **provenance allowlist** 방식을 사용한다: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in.

### 추적하는 것

| 항목 | 이유 |
|------|------|
| `CLAUDE.md` | 메인 개발 가이드라인 |
| `settings.json` | 포터블화된 플러그인·훅 설정 |
| `rules/` | 행동 규칙 파일 5종 (boundaries · git-workflow · hybrid-workflow · karpathy-principles · security) |
| `skills/hybrid-workflow-reference/` | hybrid-workflow §2–§5·§6·§7·§9를 담은 지연 로드 스킬 — `rules/`에서 분리한 손-콘텐츠라 유일하게 추적하는 스킬 |
| `memory-templates/` | 세션 간 메모리 seed (현재 본문 seed 없음, 인덱스 스캐폴드만) |
| `hooks/*.sh` | rtk-rewrite, workflow-stage-inject, graphify-install-check |
| `scripts/sync-memory-templates.sh` | 메모리 템플릿 동기화 |
| `.gitignore`, `.gitattributes`, `README.md` | 저장소 메타 |
| `PRESENTATION.pdf` | 하이브리드 워크플로우 발표자료 |

### 추적하지 않는 것 (기본 무시)

- `plugins/` — Claude Code가 자동 관리, 버전 핀 불필요
- `skills/` — 플러그인·npm이 재설치 가능. 커스텀 수정은 업스트림 회귀 또는 별도 보존. **예외**: `skills/hybrid-workflow-reference/`는 `.gitignore`에서 명시 opt-in (아래 "스킬 복원 안내")
- `memory/` — 머신별 세션 메모리, 민감 정보 포함 가능
- `node_modules/`, `security/`, `daemon/`, `sessions/` 등 런타임 산출물
- `settings.local.json` — 머신 로컬 override

### 스킬 복원 안내

- **플러그인 스킬** (compound-engineering, superpowers 등): Claude Code 재실행 시 자동 복원
- **npm 스킬** (slides-grab, slides-grab-design, slides-grab-export, slides-grab-plan): `npm install -g slides-grab`
- **CLI 스킬** (graphify): `uv tool install graphifyy`. CLI·`graphify-install-check.sh` 훅(CLAUDE.md의 graphify 섹션 자동 주입)·스킬이 한 세트로 움직인다
- **추적하는 손-작성 스킬** (`hybrid-workflow-reference`): clone만으로 복원됨. `rules/hybrid-workflow.md`가 §2–§5·§6·§7·§9 자리에서 이 스킬을 가리키므로 **둘은 같이 움직여야 한다**
- **순수 bespoke 스킬** (peon-ping-*, plannotator-annotate 등): 별도 보존 필요 (현재 미추적)

---

## 메인 하네스: Hybrid Workflow

`rules/hybrid-workflow.md`가 정식 운영 가이드다. 이 파일은 매 세션 컨텍스트에 상주하므로, 특정 시점에만 참조하는 **§2–§5(모델 재보정표·채점 근거·에스컬레이션·리뷰어 분기) · §6(유닛 분량·직렬 실행) · §7(95% confidence opener) · §9(메모리·문서 tier)** 는 본문을 `skills/hybrid-workflow-reference/`로 빼고 자리에 포인터만 남겼다.

§2–§5만은 예외적으로 **routing quick card**(채점 기저점·가산 신호·밴드표·build carve-out·sonnet 배제·리뷰어 opus 고정)를 상주 자리에 남긴다 — 라우팅 판정은 `/clear` 경계마다 필요해 매번 스킬을 로드하면 오히려 손해이기 때문이다. 스킬에는 그 판정의 *근거*(비용 역전 벤치마크, 재실행 게이트 상세, sonnet 복귀 시 되돌릴 리뷰어 분기표)만 남는다.

§1·§8·§10과 "Tier 0/1 자동 변경 금지" 금지 규칙은 전문 그대로 상주한다(금지 규칙은 지연 로드로 내리지 않는다).

요약:

```
Phase 1: Spec    superpowers:brainstorming → docs/superpowers/specs/
Phase 2: Plan    non-plan-mode: /ce-plan → docs/plans/  (자동 ce-doc-review, 사람 리뷰는 선택)
Phase 2': Build  /ce-work <plan-path>
Phase 3: Ship    verify → /ce-compound → commit+PR
```

각 단계의 model·effort는 더 이상 단계별 고정값이 아니라, **과업 복잡도를 채점**해 정해진다(`rules/hybrid-workflow.md`의 routing quick card가 정본, 근거는 `hybrid-workflow-reference` 스킬).

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
| 0–2 | 사소·기계적 | opus-5 | low | "테스트 통과 확인만" |
| 3–5 | 표준 | opus-5 | medium | "새 엔드포인트 하나 추가, 파일 3개" |
| 6–7 | 조금 어려움 | opus-5 | high | "새 의존성 도입 + 데이터 스키마 변경" |
| 8–10 | 복잡함 | opus-5 | xhigh | "새 아키텍처 결정 + API 스키마 변경 + 교차 관심사" |

예: "표준 구현(base 3) + 파일 3–5개(+2) + 동시성 얽힘(+2)" = 7점 → **opus·high**를 announce하고 현재 세션과 다르면 `/model`·`/effort` 전환을 안내한다(강제 아님).

**단, Build 단계(ce-work)는 예외다**: 완성된 계획을 실행하는 build 작업은 계획이 이미 판단을 front-load했으므로 base 1(기계적 실행)로 채점하고, 계획-시점 가산 신호(파일 수·새 모듈·API/스키마 변경)를 **다시 세지 않는다** — 그래서 파일이 아무리 많아도 기본값은 **opus·medium**이다 — 모든 밴드가 opus인 지금, 이 예외는 모델 등급을 낮추는 게 아니라 **effort를 medium으로 캡**한다(계획이 아무리 커도 build를 high/xhigh로 올리지 않음). 파일 수는 유닛 분량으로 처리한다. build가 opus로 올라가는 건 오직 **반응적**일 때뿐이다: 실행이 계획이 예견 못 한 것을 드러낼 때 — RED→GREEN 정체가 개방형 근본원인 디버깅으로 전환되거나(그 서브태스크는 base-5 디버깅으로 재채점), 되돌리기 어려운 변경에서 테스트/타입체크가 실패할 때(§4 re-run 게이트). 계획-시점 범위로는 선불 승격하지 않는다.

**fable-5**는 점수로는 절대 도달하지 않는다 — 여러 서브시스템을 넘나드는 지속적 설계·구현이나 긴 agentic 체인처럼 "진짜로 길고 복잡한" 과업임을 명시적으로 판단했을 때만 옵트인한다(점수 라우팅 상한은 opus·xhigh). haiku는 이 파이프라인에서 쓰지 않는다.

**메커니즘 제약**: 메인 에이전트는 세션 도중 자기 모델을 못 바꾼다 — `/model`·`/effort`로 announce & 전환 안내만 가능. 점수 기반 밴드가 전부 opus인 지금 `/model`은 fable long-horizon flag가 켜질 때(혹은 세션이 opus가 아닐 때)만 바뀌고, 밴드별 변화는 사실상 `/effort`만 담당한다. 서브에이전트 디스패치는 두 갈래다: `Agent` 툴은 `model`만 지정 가능(effort는 디스패치 세션에서 상속), `Workflow`의 `agent()`는 `model`+`effort` 둘 다 개별 지정 가능(완전 동적).

**리뷰어 분기**: 코드/문서 리뷰는 본질적으로 개방형 적대적 추론(base 5)이다. 원래는 가장 중요한 판정만 opus(`ce-code-review`의 correctness·security·adversarial, `ce-doc-review`의 adversarial·security-lens)로 올리고 나머지는 sonnet으로 돌렸으나, **현재는 sonnet이 라우팅에서 제외되어 전 리뷰어가 `model=opus`로 통일**되어 있다(아래 "Sonnet-5 제외" 참고). 이 opus-vs-sonnet 분기는 Sonnet 재도입 시 복원할 기준으로 `hybrid-workflow-reference` 스킬 §5에 기록되어 있다.

세션 resting 기본값(`settings.json`)은 `effortLevel: high`다 — `xhigh`는 8–10 밴드에서 과업별로만 도달하며 상시 기본값이 아니다.

**Sonnet-5 제외 (비용 역전, 한시적)**: per-token 단가만 보면 Sonnet-5가 가장 싸지만, 이 파이프라인의 다단계 agentic 작업에서는 토큰·반복이 3~4배로 불어나 **실효 비용이 Opus 4.8 이상으로 뒤집히고 정확도는 낮다**. 근거(**전부 Opus 4.8 기준 측정치다 — Opus 5로 재측정한 값이 아니므로 수치의 모델명을 바꾸지 말 것**) — BrowseComp에서 Opus·low($5/67.7%)가 Sonnet·high($7/64.8%)를 비용·정확도 모두에서 앞서고, Artificial Analysis 인덱스 전체 실행 비용은 Opus 4.8 max $3,753 < Sonnet 5 max $6,015이며, 실측 agentic 태스크에서 Opus 4.8 단독은 70회/$7.07인 반면 Sonnet 5 단독은 309회/$20.95였다(가장 싼 모델이 최종 비용은 가장 큼). 그래서 0–5 밴드와 비적대 리뷰어까지 전부 Opus로 통일한다(현재 Opus 5). **Opus 5 전환 이후 미검증**: 이 배제 판정은 위 4.8 시절 수치에만 근거한다. Opus 5의 비용·정확도 비는 이 파이프라인에서 Sonnet 5와 대조 측정된 바 없으므로, 역전은 *성립한다고 가정*할 뿐 검증된 것이 아니다. **추후 Sonnet 비용이 정상화되면** — 재벤치마크에서 해당 밴드의 검증된-결과당(cost-per-verified-outcome) 비용이 다시 Opus 아래로 내려오면 — 저비용 밴드(0–5)와 비적대 리뷰어에 Sonnet을 언제든 재도입한다. haiku는 이 파이프라인에서 쓰지 않는다.

> 참고:
> - <https://www.reddit.com/r/ClaudeAI/comments/1ujx3rw/sonnet_5_is_worse_than_opus_at_the_same_price_at/>
> - <https://www.reddit.com/r/theprimeagen/comments/1ukscqq/the_new_claude_sonnet_5_is_more_costly_than_fable/>
> - <https://devbrothers.ai/blog/advisor-%EC%A0%84%EB%9E%B5-claude-fable-5%EC%97%90%EA%B2%8C-%EC%9D%BC%EC%9D%84-%EC%8B%9C%ED%82%A4%EC%A7%80-%EB%A7%90%EA%B3%A0-%EC%8B%9C%ED%82%A4%EB%8A%94-%EC%97%AD%ED%95%A0%EC%9D%84-%EC%8B%9C%EC%BC%9C%EB%9D%BC/>

### Plan 단계 흐름 (Plan Mode ↔ Plannotator 디커플링)

`/ce-plan`의 본작업(계획 파일 작성, ce-doc-review의 자동 수정)은 Plan Mode 밖(non-plan-mode)에서 실행된다 — Plan Mode가 파일 쓰기와 자동 수정을 막기 때문이다. 리뷰가 사라지는 건 아니다: **ce-doc-review가 ce-plan의 Phase 5.3.8로 정본 파일에 자동 실행**된다.

사람이 직접 보고 싶으면 `plannotator annotate docs/plans/<file>`을 **수동으로** 돌린다 — **강제 게이트가 아니다**. Approve 버튼이 없어 피드백 없이 닫으면 승인으로 간주하고, 피드백을 남겼다면 같은 `docs/plans/YYYY-MM-DD-<summary>.md` 파일에 반영한다(파일 재사용, 원래 날짜 유지). `/clear`는 이 결과를 기다리지 않는다.

`ExitPlanMode` 브라켓도 `~/.claude/plans/` 복사본도 없어, ce-doc-review 자동 수정이 재-붙여넣기 텍스트에 덮이지 않는다(정본이 곧 리뷰 대상). 일반 Plan Mode의 `ExitPlanMode` 경로(그 `PermissionRequest` Plannotator 게이트 + `~/.claude/plans/` 승격)는 ce-plan 외 작업에 그대로 남는다.

```
non-plan-mode → /ce-plan (계획 작성) → 자동 ce-doc-review(전 리뷰어 opus)
  → (선택) plannotator annotate docs/plans/<file> → /clear
```

일반적인 "복잡한 작업 전에는 Plan Mode로 먼저 분석한다"는 규율(CLAUDE.md)은 그대로 유지된다 — 위 흐름은 `/ce-plan` 자체의 실행 방식에 대한 예외(carve-out)일 뿐이다.

### 의존 플러그인

`settings.json`의 `enabledPlugins`가 정본이다. 아래는 `true`인 것들.

| 플러그인 | 역할 |
|---------|------|
| `compound-engineering@compound-engineering-plugin` | ce-plan, ce-work, ce-code-review 등 메인 workflow |
| `superpowers@claude-plugins-official` | brainstorming, TDD, debugging 등 process skills |
| `security-guidance@claude-plugins-official` | 보안 가이드 (보안 리뷰 규칙·security-reviewer) |
| `plannotator@plannotator` | 계획 파일 브라우저 리뷰 (선택 — 강제 게이트 아님) |
| `skill-creator@claude-plugins-official` | 스킬 생성·최적화 |
| `claude-dashboard@claude-dashboard` | statusLine |

**비활성** (`enabledPlugins`에 `false`) — 사용 이력이 없어 컨텍스트에서 내린 것들이다. 필요하면 `/plugin`으로 되살린다.

| 플러그인 | 내린 이유 |
|---------|------|
| `context7@claude-plugins-official` | 라이브러리 문서 조회 — MCP 호출 기록 0건 |
| `claude-md-management@claude-plugins-official` | CLAUDE.md 감사 — 스킬 1회 사용에 그침 |
| `code-simplifier@claude-plugins-official` | 코드 단순화 — 에이전트 정의만 제공, 호출 0건 |
| `commit-commands@claude-plugins-official` | 커밋·PR — `superpowers:finishing-a-development-branch`·`ce-commit`과 3중복 |

### 의존 MCP 서버

MCP 서버 등록은 `~/.claude.json`에 있고 git으로 추적하지 않는다(머신 로컬). 활성:

- `codegraph` — symbol-level code intelligence (`.codegraph/` 인덱스). `install.sh`가 `~/.claude.json`에 자동 등록
- `arxiv` — 논문 검색·다운로드 (수동 등록, `read-arxiv-paper` 스킬이 사용)

**비활성** — `disabledMcpServers`로 내렸다. **이 설정은 프로젝트별**이라 다른 프로젝트에서도 끄려면 거기서 `/mcp disable`을 다시 실행해야 한다.

- `sequential-thinking` — 다단계 추론. 호출 기록 0건
- `context7` — 호출 기록 0건. 같은 기능의 `context7@claude-plugins-official` 플러그인도 함께 내렸으므로, 라이브러리 문서 조회를 되살리려면 **둘 중 하나만** 켜면 된다(둘 다 켜면 중복 등록)

> `computer-use`·`claude-in-chrome` 등은 Claude Code 내장/커넥터라 `~/.claude.json`의 `mcpServers`에 없다.

---

## 메모리 Seed

`memory-templates/`는 세션 메모리의 seed용 템플릿 디렉토리다. git으로 추적된다.

라이브 메모리 중 보존하고 싶은 것은 `memory-templates/`에 파일을 추가하면 `scripts/sync-memory-templates.sh`로 동기화할 수 있다.

```bash
# 메모리 템플릿 동기화
bash scripts/sync-memory-templates.sh
```

> **현재 본문 seed 없음** (`MEMORY-index.md` 스캐폴드만). 이전의 `feedback_hybrid_workflow.md` seed는 내용이 체크인된 `rules/hybrid-workflow.md` §1·§9·§10과 중복이라 제거했다 — 메모리는 규칙 파일이 못 담는 것만 담는다.

---

## settings.json 포터블화 정책

- 절대경로 없음 — 모든 경로는 `$HOME` 기반
- statusLine은 버전 핀 없이 glob으로 최신 버전 자동 사용
- peon-ping 훅 없음 (머신 로컬 취향, 공개 제외)
- `permissions.allow` 없음 (Claude가 grant 시 재기입하므로 초기 커밋만 깨끗하면 됨)
- `permissions.defaultMode: "auto"`는 예외적으로 커밋한다 — grant 누적물이 아니라 의도적인 정책이고, auto 모드는 user·policy 스코프에서만 인정되어 프로젝트 설정으로는 옮길 수 없다
- `skillOverrides`로 미사용 스킬 30개를 `"off"` 처리 — 스킬 목록은 컨텍스트에 상주하므로 안 쓰는 항목은 매 세션 비용이다. 되살리려면 해당 키를 지운다
- **사용 이력이 0이어도 살아 있는 스킬이 참조하면 켜 둔다** — 라우팅 대상이 꺼지면 매달린 포인터가 된다. 현재 해당: `fastapi-project-structure`(`python-architecture`가 FastAPI 프로젝트를 넘김), `slides-grab-card-news`(`slides-grab`·`slides-grab-export`가 card-news 덱을 넘김)

> **주의**: `settings.json`은 skip-worktree가 걸려 있어 위 변경들이 `git status`·`git diff`에 뜨지 않는다. 커밋하려면 `git update-index --no-skip-worktree settings.json`으로 잠깐 풀고 커밋한 뒤 다시 건다.
