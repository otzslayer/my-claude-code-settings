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
- **jq** — 컴포넌트 선택과 무관하게 항상 확인·설치한다. `rtk-rewrite.sh` · `workflow-stage-inject.sh` · `settings.json` 인라인 `PreToolUse` 훅 2종(`.py` 편집 시 python-coding-style 주입, `docs/plans/*.md` 한국어 강제)이 전부 jq 하드 의존이라, 없으면 이들이 **조용히** 죽는다
- **node/npm 전제 확인** — statusLine(claude-dashboard)이 `node`로 직접 실행되므로 slides-grab을 고르지 않아도 확인한다 (없으면 경고)
- rtk (token optimizer) + `rtk init -g` (RTK.md 생성 — 순서 보장)
- codegraph (symbol-level code intelligence) — `~/.claude.json`에 MCP 자동 등록 (idempotent)
- graphify (knowledge graph CLI)
- slides-grab (npm 패키지)
- plannotator (계획 파일 브라우저 리뷰 UI 바이너리 — plannotator 플러그인 prerequisite)
- 메모리 seed 동기화 (`memory-templates/`)
- `settings.json` skip-worktree 적용 (permissions 재유입 방지)
- **훅·의존성 점검** — 설치 말미에 `settings.json`이 실제로 호출하는 훅·statusLine 커맨드를 **설정에서 추출해** PATH·존재·실행권한을 확인하고(커맨드 목록을 하드코딩하지 않으므로 저장소에 없는 머신 로컬 훅도 그대로 걸린다), 추적 스킬 4종과 `RTK.md`가 제자리에 있는지 본다. 미해결 항목은 마지막 요약에 모아 출력한다

> **추적 스킬은 설치 단계가 없다**: 저장소 루트가 곧 `~/.claude`라 `skills/` 4종은 clone만으로 Claude Code가 읽는 위치에 놓이고, 실행 비트도 git이 보존한다. 위 점검 섹션은 설치가 아니라 **누락 감지**용이다.

> **skip-worktree**: Claude 세션 중 grant가 `settings.json`에 재기입되어 `git status`가 dirty가 되는 현상을 방지한다. `install.sh`가 자동 실행하나, clone 후 재실행이 필요하다. 해제: `git update-index --no-skip-worktree settings.json`

설치 후 **Claude Code를 재시작**하면 `settings.json`의 `enabledPlugins`가 읽혀 플러그인이 자동 설치된다.

---

### 수동 설치

> **중요**: 아래 순서를 반드시 지킬 것. `rtk init -g`를 먼저 실행하지 않으면 CLAUDE.md의 `@RTK.md` import가 깨진다.

#### 1단계: RTK 설치 (최우선)

```bash
# RTK (token optimizer) 설치 — brew tap이 없다면 GitHub Releases에서 직접 설치
brew install reachingforthejack/rtk/rtk   # 또는 릴리즈 바이너리 직접 설치

# jq — 훅 전체의 하드 의존 (rtk-rewrite · workflow-stage-inject ·
#      settings.json 인라인 훅 2종이 모두 조용히 비활성화됨). rtk를 안 써도 필요하다.
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

> **참고**: `skills/`는 원칙적으로 추적하지 않는다(손-작성 스킬 4종 — `hybrid-workflow-reference` · `fastapi-project-structure` · `python-architecture` · `python-coding-style` — 만 예외). 플러그인 스킬은 Claude Code가 자동 설치하고, npm/CLI 스킬(slides-grab*, graphify)은 위 2단계에서 직접 설치해야 한다.

---

## Tracking 정책

`.gitignore`는 **provenance allowlist** 방식을 사용한다: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in.

### 추적하는 것

| 항목 | 이유 |
|------|------|
| `CLAUDE.md` | 메인 개발 가이드라인 |
| `settings.json` | 포터블화된 플러그인·훅 설정 |
| `rules/` | 행동 규칙 파일 5종 (boundaries · git-workflow · hybrid-workflow · karpathy-principles · security) |
| `skills/hybrid-workflow-reference/` | hybrid-workflow 지연 로드 스킬 — `SKILL.md`는 인덱스뿐이고 본문은 `references/` 5개 파일에 주제별로 나뉘어 있다. `rules/`에서 분리한 손-콘텐츠 |
| `skills/fastapi-project-structure/` | FastAPI 스캐폴딩 스킬 (템플릿·스크립트·예제·evals). CLAUDE.md 스킬 표에서 직접 호출하는 손-작성 스킬 — 재설치 경로가 없다. `SKILL.md.bak`은 백업 생성물이라 제외 |
| `skills/python-architecture/` | Python 레이어드 아키텍처 스킬 (`SKILL.md` 단일 파일). 위와 같은 이유로 추적 |
| `skills/python-coding-style/` | Python 스타일 규칙 (`SKILL.md` 단일 파일). **ruff 설정의 원본** — `fastapi-project-structure`의 `pyproject-template.toml`이 이걸 인스턴스화하므로 둘은 같이 움직여야 한다 |
| `memory-templates/` | 세션 간 메모리 seed (현재 본문 seed 없음, 인덱스 스캐폴드만) |
| `hooks/*.sh` | rtk-rewrite, workflow-stage-inject, graphify-install-check |
| `scripts/sync-memory-templates.sh` | 메모리 템플릿 동기화 |
| `.gitignore`, `.gitattributes`, `README.md` | 저장소 메타 |
| `PRESENTATION.pdf` | 하이브리드 워크플로우 발표자료 |

### 추적하지 않는 것 (기본 무시)

- `plugins/` — Claude Code가 자동 관리, 버전 핀 불필요
- `skills/` — 플러그인·npm이 재설치 가능. 커스텀 수정은 업스트림 회귀 또는 별도 보존. **예외**: `hybrid-workflow-reference/` · `fastapi-project-structure/` · `python-architecture/` · `python-coding-style/`는 `.gitignore`에서 명시 opt-in (아래 "스킬 복원 안내")
- `memory/` — 머신별 세션 메모리, 민감 정보 포함 가능
- `node_modules/`, `security/`, `daemon/`, `sessions/` 등 런타임 산출물
- `settings.local.json` — 머신 로컬 override

### 스킬 복원 안내

- **플러그인 스킬** (compound-engineering, superpowers 등): Claude Code 재실행 시 자동 복원
- **npm 스킬** (slides-grab, slides-grab-design, slides-grab-export, slides-grab-plan): `npm install -g slides-grab`
- **CLI 스킬** (graphify): `uv tool install graphifyy`. CLI·`graphify-install-check.sh` 훅(CLAUDE.md의 graphify 섹션 자동 주입)·스킬이 한 세트로 움직인다
- **추적하는 손-작성 스킬** (`hybrid-workflow-reference`, `fastapi-project-structure`, `python-architecture`, `python-coding-style`): clone만으로 복원됨. `hybrid-workflow-reference`는 `rules/hybrid-workflow.md`가 §3·§4·§6·§7·§9 자리에서 이 스킬의 `references/` 파일을 **파일명으로** 가리키므로 **둘은 같이 움직여야 한다** (파일을 옮기거나 이름을 바꾸면 상주 포인터도 같이 고칠 것). 나머지 셋은 CLAUDE.md 스킬 표(Python 작성 / 새 Python·FastAPI 프로젝트 레이아웃)에서 호출하는 손-콘텐츠라 재설치 경로가 없다. **`python-coding-style`이 ruff 설정의 원본이고 `fastapi-project-structure/templates/pyproject-template.toml`이 그 인스턴스**이므로, 한쪽을 고치면 다른 쪽도 같이 고친다
- **순수 bespoke 스킬** (peon-ping-*, plannotator-annotate 등): 별도 보존 필요 (현재 미추적)

---

## 메인 하네스: Hybrid Workflow

`rules/hybrid-workflow.md`가 정식 운영 가이드다. 이 파일은 매 세션 컨텍스트에 상주하므로, 특정 시점에만 참조하는 **§3–§5(채점 근거·에스컬레이션·리뷰어 dispatch) · §6(유닛 분량·직렬 실행) · §7(95% confidence opener) · §9(메모리·문서 tier)** 는 본문을 `skills/hybrid-workflow-reference/`로 빼고 자리에 포인터만 남겼다.

§3–§5만은 예외적으로 **routing quick card**(채점 기저점·가산 신호·밴드표·build carve-out·리뷰어 opus 고정)를 상주 자리에 남긴다 — 라우팅 판정은 `/clear` 경계마다 필요해 매번 파일을 로드하면 오히려 손해이기 때문이다. 지연 로드 쪽에는 그 판정의 *근거*만 남는다.

**스킬 내부도 주제별로 쪼개져 있다.** 스킬 본문은 한 번 로드되면 세션 끝까지 컨텍스트에 남고, 이 파이프라인은 단계마다 `/clear`를 강제한다 — 380토큰이 필요해 3.7k를 통째로 불러오면 그 세션 내내 나머지를 짊어진다. 그래서 `SKILL.md`는 1k 미만 인덱스만 두고 본문을 나눴다:

| 파일 | 내용 | 읽는 시점 |
| --- | --- | --- |
| `references/scoring.md` | §3 채점 근거 · §4 에스컬레이션 | effort 판정이 애매할 때 |
| `references/units.md` | §6 유닛 분량·직렬 실행 | ce-plan U-ID 묶을 때, ce-work 직렬/병렬 고를 때 |
| `references/brainstorming.md` | §7 5렌즈 정의 | **제품성** 브레인스토밍일 때만 |
| `references/tiers.md` | §9 메모리·문서 tier | 파일 배치 결정 시 |

§3·§4는 서로를 계속 되참조해서(§3의 경계 반올림→§4, §4의 build 격상→§3 carve-out) 한 파일로 묶었다. 더 쪼개면 한쪽을 열자마자 다른 쪽이 필요해져 왕복만 늘어난다.

**§5(리뷰어 dispatch)에는 지연 로드할 게 남지 않았다.** 원래는 opus-vs-sonnet 분기표가 본문이었는데 그게 사라지면서, 남은 건 quick card가 이미 담고 있는 `model=opus` pin·플러그인 수정 금지·세션 모델 전환 금지뿐이다. "ce-doc-review는 ce-plan과 같은 세션에서 돌아 전환할 `/clear` 경계가 없다"는 사실만 quick card 리뷰어 불릿에 접어 넣고 `references/reviewers.md`는 삭제했다.

§7의 opener 원문과 "한 번에 한 질문" 계약은 **어느 파일에도 없다** — `hooks/workflow-stage-inject.sh`가 brainstorming 호출 직후 그 자리에 주입한다(상주 비용 0). `references/brainstorming.md`에는 훅이 이름만 던지는 5렌즈의 정의만 있다.

§1·§8·§10과 "Tier 0/1 자동 변경 금지" 금지 규칙은 전문 그대로 상주한다(금지 규칙은 지연 로드로 내리지 않는다).

**§2(모델 재보정표)는 없앴다.** 모델을 Opus 5 하나로 고정했으므로 모델 간 비교표·비용 근거는 어디에도 두지 않는다 — 채점이 정하는 건 `effort`뿐이다.

요약:

```
Phase 1: Spec    superpowers:brainstorming → docs/superpowers/specs/
Phase 2: Plan    non-plan-mode: /ce-plan → docs/plans/  (자동 ce-doc-review, 사람 리뷰는 선택)
Phase 2': Build  /ce-work <plan-path>
Phase 3: Ship    verify → /ce-compound → commit+PR
```

각 단계의 effort는 더 이상 단계별 고정값이 아니라, **과업 복잡도를 채점**해 정해진다(`rules/hybrid-workflow.md`의 routing quick card가 정본, 근거는 `hybrid-workflow-reference` 스킬). 모델은 **Opus 5 고정**이다.

### effort는 어떻게 정해지나 (복잡도 채점)

과업마다 **기저점**(인지 성격)에 **가산 신호**(범위)를 더해 0–10점을 매기고, 점수 구간(밴드)이 effort를 정한다.

| 기저점 | 예 | 점수 |
|---|---|---|
| 기계적 실행 | 빌드·검증·리네임·포맷 | 1 |
| 표준 구현 | 잘 정의된 기능·바운드된 버그 | 3 |
| 개방형 추론 | 설계·브레인스토밍·근본원인 디버깅 | 5 |

여기에 파일 수(+1~+3), 새 모듈/아키텍처 결정(+2), 새 의존성(+1), API·스키마 변경(+2), 동시성/보안/마이그레이션 같은 교차 관심사(+2), 실질적 모호성(+2)이 해당할 때마다 더해진다(상한 10).

| 점수 | 밴드 | effort | 예시 |
|---|---|---|---|
| 0–2 | 사소·기계적 | low | "테스트 통과 확인만" |
| 3–5 | 표준 | medium | "새 엔드포인트 하나 추가, 파일 3개" |
| 6–7 | 조금 어려움 | high | "새 의존성 도입 + 데이터 스키마 변경" |
| 8–10 | 복잡함 | xhigh | "새 아키텍처 결정 + API 스키마 변경 + 교차 관심사" |

예: "표준 구현(base 3) + 파일 3–5개(+2) + 동시성 얽힘(+2)" = 7점 → **high**를 announce하고 현재 세션과 다르면 `/effort` 전환을 안내한다(강제 아님).

**단, Build 단계(ce-work)는 예외다**: 완성된 계획을 실행하는 build 작업은 계획이 이미 판단을 front-load했으므로 base 1(기계적 실행)로 채점하고, 계획-시점 가산 신호(파일 수·새 모듈·API/스키마 변경)를 **다시 세지 않는다** — 그래서 파일이 아무리 많아도 기본값은 **medium**이다. 이 예외는 계획이 아무리 커도 build를 high/xhigh로 올리지 못하도록 **effort에 상한을 씌우는** 장치이며, 파일 수는 effort가 아니라 유닛 분량으로 처리한다. build가 올라가는 건 오직 **반응적**일 때뿐이다: 실행이 계획이 예견 못 한 것을 드러낼 때 — RED→GREEN 정체가 개방형 근본원인 디버깅으로 전환되거나(그 서브태스크는 base-5 디버깅으로 재채점), 되돌리기 어려운 변경에서 테스트/타입체크가 실패할 때(§4 re-run 게이트). 계획-시점 범위로는 선불 승격하지 않는다.

**메커니즘 제약**: 메인 에이전트는 세션 도중 자기 effort를 못 바꾼다 — `/effort`로 announce & 전환 안내만 가능하다. 모델은 Opus 5 고정이라 `/model`은 세션이 Opus 5가 아닐 때만 언급하면 된다. 서브에이전트 디스패치는 두 갈래다: `Agent` 툴은 `model`만 지정 가능(effort는 디스패치 세션에서 상속), `Workflow`의 `agent()`는 `model`+`effort` 둘 다 개별 지정 가능(완전 동적).

**리뷰어**: 코드/문서 리뷰는 본질적으로 개방형 적대적 추론(base 5)이라 리뷰어는 전원 `model=opus`로 dispatch한다. 이 pin은 "어차피 Opus만 쓰니까 불필요"가 아니다 — 플러그인 스킬(`~/.claude/plugins/...`)이 자체 모델 티어링을 갖고 있고 업데이트마다 되살아나므로, 상주 규칙 파일이 그걸 덮어쓰는 강제 지점이다. 플러그인 스킬 자체를 고쳐서 해결하지 않는다(머신 상태라 덮어써진다).

세션 resting 기본값(`settings.json`)은 `effortLevel: high`다 — `xhigh`는 8–10 밴드에서 과업별로만 도달하며 상시 기본값이 아니다.

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
