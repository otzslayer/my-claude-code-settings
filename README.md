# my-claude-code-settings

`~/.claude`를 git으로 추적하는 개인 설정 저장소. 개인 멀티머신 백업과 공개를 동시에 지원하도록 설계됐다.

**메인 하네스**: Superpowers 단독 워크플로우 (`CLAUDE.md`의 스킬 표가 정본)

**발표자료**: [`PRESENTATION.pdf`](PRESENTATION.pdf) — 이전 하이브리드 워크플로우 발표 자료(아카이브)

---

## 설치

### 자동 설치 (권장)

```bash
git clone https://github.com/otzslayer/my-claude-code-settings.git ~/.claude
bash ~/.claude/scripts/install.sh
```

`scripts/install.sh`는 gum TUI 기반 인터랙티브 설치기다. macOS와 WSL2를 지원하며, gum이 없으면 plain read 폴백으로 동작한다.

**설치기가 처리하는 항목**:
- **jq** — 컴포넌트 선택과 무관하게 항상 확인·설치한다. `rtk-rewrite.sh` · `workflow-stage-inject.sh` · `settings.json` 인라인 `PreToolUse` 훅 2종(`.py` 편집 시 python-coding-style 주입, `docs/plans/*.md`·`docs/superpowers/specs/*.md` 한국어 강제)이 전부 jq 하드 의존이라, 없으면 이들이 **조용히** 죽는다
- **ugrep · bfs** — 컴포넌트 선택과 무관하게 항상 확인·설치한다. `rules/boundaries.md`의 검색 가이드가 아카이브 검색(`-z`)·퍼지 매칭·빠른 breadth-first find를 전제한다. jq와 달리 **소프트 의존**이라 없으면 `grep`·`find`로 폴백되므로, 실패해도 경고만 남기고 점검 미해결 항목에는 넣지 않는다
- **node/npm 전제 확인** — statusLine(claude-dashboard)이 `node`로 직접 실행되므로 slides-grab을 고르지 않아도 확인한다 (없으면 경고)
- rtk (token optimizer) + `rtk init -g` (RTK.md 생성 — 순서 보장) + `rtk config`의 `[hooks] exclude_commands`에 `grep`·`find` 추가 — 네이티브 빌드는 셸 스냅샷에서 `grep`·`find`를 임베디드 ugrep·bfs로 shadow하는데, rtk가 `rtk grep`으로 재작성하면 별도 프로세스의 BSD grep이 돌아 gitignore 인식(`--ignore-files`)을 잃는다 (`rtk rg`는 ripgrep을 그대로 실행하므로 제외하지 않음)
- codegraph (symbol-level code intelligence) — `~/.claude.json`에 MCP 자동 등록 (idempotent)
- graphify (knowledge graph CLI)
- slides-grab (npm 패키지)
- plannotator (계획 파일 브라우저 리뷰 UI 바이너리 — plannotator 플러그인 prerequisite)
- 메모리 seed 동기화 (`memory-templates/`)
- `settings.json` 로컬 블록 clean/smudge 필터 등록 (머신 로컬 훅 커밋 차단)
- **훅·의존성 점검** — 설치 말미에 `settings.json`이 실제로 호출하는 훅·statusLine 커맨드를 **설정에서 추출해** PATH·존재·실행권한을 확인하고(커맨드 목록을 하드코딩하지 않으므로 저장소에 없는 머신 로컬 훅도 그대로 걸린다), 추적 스킬 4종과 `RTK.md`가 제자리에 있는지 본다. 미해결 항목은 마지막 요약에 모아 출력한다

> **추적 스킬은 설치 단계가 없다**: 저장소 루트가 곧 `~/.claude`라 `skills/` 4종은 clone만으로 Claude Code가 읽는 위치에 놓이고, 실행 비트도 git이 보존한다. 위 점검 섹션은 설치가 아니라 **누락 감지**용이다.

> **settings.json 로컬 블록 필터**: grrr 알림 훅(`Stop`·`Notification`·`UserPromptSubmit`)은 이 머신에만 설치된 CLI에 의존하지만, 모든 프로젝트에서 울리려면 `~/.claude/settings.json` 안에 있어야 한다 — Claude Code의 `localSettings`는 언제나 `<프로젝트 루트>/.claude/settings.local.json`이라 user 스코프에는 local 오버레이가 없다. git에는 파일 내부 블록 단위 추적 제외가 없으므로, `.gitattributes`의 `/settings.json filter=claude-local`과 `scripts/git-filter-settings.sh`로 **커밋 경로에서만** 걷어낸다. clean이 해당 훅 이벤트를 지우고, smudge가 `local-hooks.json`(`.gitignore` 대상)에서 되살린다. 복원 원본이므로 `local-hooks.json`을 지우면 checkout 후 훅이 사라진다.
>
> ⚠️ **필터 설정은 `.git/config`에 살아 clone을 따라가지 않는다.** `.gitattributes`는 커밋되지만 필터 드라이버가 정의되지 않은 clone에서 git은 **경고 없이 원본을 그대로 통과시킨다** — 실측 확인함. 즉 `required = true`는 *등록된* clone에서 필터 스크립트가 깨졌을 때(jq 없음, 스크립트 삭제) 조용한 통과 대신 실패시키는 보호이고, *미등록* clone에는 아무 보호도 주지 못한다. 실질 안전장치는 **clone 후 `install.sh` 재실행**뿐이다. 확인: `git config --get filter.claude-local.clean` (비어 있으면 미등록).
>
> 이전 버전이 쓰던 `git update-index --skip-worktree settings.json`은 파일 **전체**를 숨겨 `settings.json` 커밋 자체를 막으므로 더 이상 쓰지 않는다 — `install.sh`가 발견하면 해제한다. 다만 그 플래그가 겸하던 **`permissions.allow` 재유입 억제**는 이 필터가 대신하지 않는다. grant가 다시 `settings.json`을 더럽히기 시작하면 `scripts/git-filter-settings.sh`의 `LOCAL_KEYS`를 넓히는 쪽으로 대응한다 (skip-worktree 복귀는 커밋을 막으므로 답이 아니다).

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

# ugrep · bfs — boundaries.md 검색 가이드의 전제(아카이브 -z · 퍼지 · 빠른 find).
#               소프트 의존이라 없으면 grep·find로 폴백된다.
brew install ugrep bfs   # Linux/WSL2: sudo apt-get install -y ugrep bfs

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

#### 4단계: settings.json 로컬 블록 필터 등록

`install.sh`를 돌렸다면 이미 끝난 단계다. 수동으로 걸려면:

```bash
git config filter.claude-local.clean  "scripts/git-filter-settings.sh clean"
git config filter.claude-local.smudge "scripts/git-filter-settings.sh smudge"
git config filter.claude-local.required true
```

#### 5단계: Claude Code 첫 실행

```bash
claude
```

Claude Code가 `settings.json`의 `enabledPlugins`와 `extraKnownMarketplaces`를 읽어 플러그인을 자동 설치한다. 플러그인 캐시(`plugins/cache/`)가 생성된 뒤 statusLine이 점등된다.

> **참고**: `skills/`는 원칙적으로 추적하지 않는다(손-작성 스킬 3종 — `fastapi-project-structure` · `python-architecture` · `python-coding-style` — 만 예외). 플러그인 스킬은 Claude Code가 자동 설치하고, npm/CLI 스킬(slides-grab*, graphify)은 위 2단계에서 직접 설치해야 한다.

---

## Tracking 정책

`.gitignore`는 **provenance allowlist** 방식을 사용한다: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in.

### 추적하는 것

| 항목 | 이유 |
|------|------|
| `CLAUDE.md` | 메인 개발 가이드라인 |
| `settings.json` | 포터블화된 플러그인·훅 설정 |
| `rules/` | 행동 규칙 파일 4종 (boundaries · git-workflow · karpathy-principles · security) |
| `skills/fastapi-project-structure/` | FastAPI 스캐폴딩 스킬 (템플릿·스크립트·예제·evals). CLAUDE.md 스킬 표에서 직접 호출하는 손-작성 스킬 — 재설치 경로가 없다. `SKILL.md.bak`은 백업 생성물이라 제외 |
| `skills/python-architecture/` | Python 레이어드 아키텍처 스킬 (`SKILL.md` 단일 파일). 위와 같은 이유로 추적 |
| `skills/python-coding-style/` | Python 스타일 규칙 (`SKILL.md` 단일 파일). **ruff 설정의 원본** — `fastapi-project-structure`의 `pyproject-template.toml`이 이걸 인스턴스화하므로 둘은 같이 움직여야 한다 |
| `memory-templates/` | 세션 간 메모리 seed (현재 본문 seed 없음, 인덱스 스캐폴드만) |
| `hooks/*.sh` | rtk-rewrite, workflow-stage-inject, graphify-install-check |
| `scripts/sync-memory-templates.sh` | 메모리 템플릿 동기화 |
| `.gitignore`, `.gitattributes`, `README.md` | 저장소 메타 |
| `PRESENTATION.pdf` | 이전 하이브리드 워크플로우 발표자료 (아카이브) |

### 추적하지 않는 것 (기본 무시)

- `plugins/` — Claude Code가 자동 관리, 버전 핀 불필요
- `skills/` — 플러그인·npm이 재설치 가능. 커스텀 수정은 업스트림 회귀 또는 별도 보존. **예외**: `fastapi-project-structure/` · `python-architecture/` · `python-coding-style/`는 `.gitignore`에서 명시 opt-in (아래 "스킬 복원 안내")
- `docs/plans/` — **이 저장소만의 예외**. 계획 파일은 삭제 금지 원칙상 프로젝트 저장소에서는 git 추적 대상이지만(`git clean`·머신 이동에서 살아남아야 한다), 여기는 공개 저장소라 무시를 유지한다. 삭제 금지 규칙 자체는 그대로 적용되며 워킹트리에만 존재한다
- `memory/` — 머신별 세션 메모리, 민감 정보 포함 가능
- `node_modules/`, `security/`, `daemon/`, `sessions/` 등 런타임 산출물
- `settings.local.json` — 머신 로컬 override

### 스킬 복원 안내

- **플러그인 스킬** (superpowers 단독 — compound-engineering은 `enabledPlugins`에서 비활성): Claude Code 재실행 시 자동 복원
- **npm 스킬** (slides-grab, slides-grab-design, slides-grab-export, slides-grab-plan): `npm install -g slides-grab`
- **CLI 스킬** (graphify): `uv tool install graphifyy`. CLI·`graphify-install-check.sh` 훅(CLAUDE.md의 graphify 섹션 자동 주입)·스킬이 한 세트로 움직인다
- **추적하는 손-작성 스킬** (`fastapi-project-structure`, `python-architecture`, `python-coding-style`): clone만으로 복원됨. CLAUDE.md 스킬 표(Python 작성 / 새 Python·FastAPI 프로젝트 레이아웃)에서 호출하는 손-콘텐츠라 재설치 경로가 없다. **`python-coding-style`이 ruff 설정의 원본이고 `fastapi-project-structure/templates/pyproject-template.toml`이 그 인스턴스**이므로, 한쪽을 고치면 다른 쪽도 같이 고친다
- **순수 bespoke 스킬** (peon-ping-*, plannotator-annotate 등): 별도 보존 필요 (현재 미추적)

---

## 메인 하네스: Superpowers 파이프라인

워크플로우는 Superpowers 스킬만으로 구성한다. Compound Engineering 플러그인은 `enabledPlugins`에서 **비활성**이다 — `skillOverrides`가 플러그인 스킬을 커버하지 못해, `/ce-compound` 하나를 살리려면 쓰지 않는 CE 스킬 23개의 리스팅 비용(약 2,400 토큰/세션)을 함께 지불해야 했기 때문이다. 정본은 `CLAUDE.md`의 **High-Priority Workflow Skills 표**와 **Planning Trigger** 섹션이고, 단계별 just-in-time 지침은 `hooks/workflow-stage-inject.sh`가 스킬 호출 직후에 주입한다(상주 비용 0).

```
Phase 1  brainstorming        → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
Phase 2  writing-plans        → docs/plans/YYYY-MM-DD-<feature>.md
           └ /clear 여부는 여기서 에이전트가 제안하고 사용자가 결정한다 (아래 참고)
Phase 3  subagent-driven-development
           ├ 태스크마다: 구현 서브에이전트 → 태스크 리뷰(spec 준수 + 코드 품질)
           └ 마지막: 전체 브랜치 리뷰
         verification-before-completion
         finishing-a-development-branch
```

**학습 누적 단계는 비어 있다.** 초판 계획은 여기에 `/ce-compound`를 뒀지만, 플러그인 비활성화와 함께 제거했다. 대체할 커스텀 회고 스킬은 별건으로 설계·구현한다 — 존재하지 않는 스킬을 가리키는 포인터를 남기지 않기 위해, 그 스킬이 생기기 전까지 파이프라인에 자리만 잡아 두지 않는다.

**실행 스킬은 `subagent-driven-development`(SDD)다.** `executing-plans`는 SKILL.md 자체가 서브에이전트 없는 하네스용 폴백으로 자신을 규정하고, 쓸 수 있으면 SDD를 쓰라고 명시한다 — Claude Code는 그 목록에 들어 있다. 토큰 측면에서도 같은 결론이다: 단일 세션 실행은 매 턴 그때까지 쌓인 컨텍스트를 다시 읽어 턴 수에 대해 O(N²)로 늘지만, SDD는 spawn마다 컨텍스트가 리셋되므로 O(N)이다. 3태스크 이하의 작은 계획에서는 단일 세션이 조금 싸지만(교차점은 대략 5~7태스크), SDD가 붙이는 태스크별 리뷰와 전체 브랜치 리뷰의 값으로 그 차이를 지불한다.

**SDD의 종료 단계는 훅이 가로챈다.** SDD는 전체 브랜치 리뷰가 깨끗해지면 스스로 `finishing-a-development-branch`를 호출하며 끝나는데, 그대로 두면 `verification-before-completion`이 건너뛰어진다. `hooks/workflow-stage-inject.sh`의 `*subagent-driven-development` case가 이 지점에서 순서를 바로잡는다. 또 SDD가 최종 리뷰에 `requesting-code-review`의 리뷰어를 내부적으로 dispatch하므로, `requesting-code-review`는 파이프라인의 별도 단계가 아니라 **계획 실행과 무관한 단독 리뷰 요청용**으로만 남는다.

**`/clear` 경계는 강제가 아니라 제안이다.** Superpowers 스킬 트리 전체에 `/clear` 언급이 **0회**다 — 이 플러그인의 컨텍스트 격리 수단은 세션 비우기가 아니라 서브에이전트다. `brainstorming/SKILL.md`는 terminal state가 `writing-plans` 호출이라고 못박고("다른 스킬은 호출하지 마라"), `writing-plans/SKILL.md`의 Execution Handoff는 계획 저장 **직후 같은 세션에서** SDD를 제안한다. 그래서 이전에 두 곳(Phase 1 뒤·Phase 2 뒤)에 걸어 뒀던 강제 `/clear`를 걷어냈다.

대신 **계획 작성이 끝난 시점에 에이전트가 작업 특성을 보고 한쪽을 권하고 근거를 한 줄로 밝힌다**(훅의 `*writing-plans` case가 그 지시를 주입한다). `/clear`를 권하는 쪽: 태스크가 많거나(대략 5개 이상) 계획 과정에서 폐기된 선택지·중간 검색 결과가 많이 쌓인 경우 — SDD 코디네이터가 그것을 전부 물려받기 때문이다. 이어가길 권하는 쪽: 계획이 작고 컨텍스트가 얇은 경우. 결정은 사용자가 한다. 어느 쪽이든 **계획 세션에서 직접 코드를 쓰는 것은 금지**다 — 구현은 SDD가 신선한 서브에이전트로 한다.

**계획 파일은 영구 보존물이다.** 경로는 `docs/plans/`이고(`writing-plans` 기본값인 `docs/superpowers/plans/`를 override한다 — `docs/superpowers/`에는 스펙만 산다), **작업이 끝나도 삭제하지 않는다.** 계획 세션과 구현 세션 사이를 건너 살아남는 유일한 산출물이자 변경의 근거 기록이기 때문이다. 프로젝트 저장소에서는 `docs/plans/`를 git 추적 대상으로 둬 `git clean`과 머신 이동에서 보호한다. **이 저장소는 공개용이라 유일한 예외**로 무시를 유지하며, 삭제 금지 규칙만 그대로 적용된다. 이 규칙은 `CLAUDE.md`(Plan Persistence) · `rules/boundaries.md`(Never) · 훅의 `*writing-plans`·`*finishing-a-development-branch` case 세 곳에 심어져 있다.

### 모델 · effort

**사용자가 `/model`·`/effort`로 직접 설정한다.** 에이전트는 과업 복잡도를 채점하지 않고 전환을 제안하지도 않는다. 세션 resting 기본값은 `settings.json`의 `effortLevel: high`이고, 모델은 Opus 5다.

서브에이전트 디스패치는 두 갈래다: `Agent` 툴은 `model`만 지정 가능하고 `effort`는 디스패치 세션에서 상속된다. `Workflow`의 `agent()`는 `model`·`effort` 둘 다 개별 지정 가능하다.

### 의존 플러그인

`settings.json`의 `enabledPlugins`가 정본이다. 아래는 `true`인 것들.

| 플러그인 | 역할 |
|---------|------|
| `superpowers@claude-plugins-official` | brainstorming, TDD, debugging 등 process skills |
| `security-guidance@claude-plugins-official` | 보안 가이드 (보안 리뷰 규칙·security-reviewer) |
| `plannotator@plannotator` | 계획 파일 브라우저 리뷰 (선택 — 강제 게이트 아님) |
| `skill-creator@claude-plugins-official` | 스킬 생성·최적화 |
| `claude-dashboard@claude-dashboard` | statusLine |

**비활성** (`enabledPlugins`에 `false`) — 사용 이력이 없어 컨텍스트에서 내린 것들이다. 필요하면 `/plugin`으로 되살린다.

| 플러그인 | 내린 이유 |
|---------|------|
| `compound-engineering@compound-engineering-plugin` | 파이프라인이 Superpowers 단독으로 바뀌었다. `skillOverrides`가 플러그인 스킬을 커버하지 못해(짧은 키·접두사 키 두 형식 모두 실패) `/ce-compound` 하나를 살리려면 쓰지 않는 CE 스킬 23개의 리스팅 비용까지 매 세션 지불해야 했다 — 약 2,400 토큰. 학습 누적은 커스텀 회고 스킬로 대체할 예정 |
| `context7@claude-plugins-official` | 라이브러리 문서 조회 — MCP 호출 기록 0건 |
| `claude-md-management@claude-plugins-official` | CLAUDE.md 감사 — 스킬 1회 사용에 그침 |
| `code-simplifier@claude-plugins-official` | 코드 단순화 — 에이전트 정의만 제공, 호출 0건 |
| `commit-commands@claude-plugins-official` | 커밋·PR — `superpowers:finishing-a-development-branch`와 중복 |

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

> **현재 본문 seed 없음** (`MEMORY-index.md` 스캐폴드만). 이전의 `feedback_hybrid_workflow.md` seed는 체크인된 규칙 파일과 중복이라 제거했다 — 메모리는 규칙 파일이 못 담는 것만 담는다.

---

## settings.json 포터블화 정책

- 절대경로 없음 — 모든 경로는 `$HOME` 기반
- statusLine은 버전 핀 없이 glob으로 최신 버전 자동 사용
- peon-ping 훅 없음 (머신 로컬 취향, 공개 제외)
- `permissions.allow` 없음 (Claude가 grant 시 재기입하므로 초기 커밋만 깨끗하면 됨)
- `permissions.defaultMode: "auto"`는 예외적으로 커밋한다 — grant 누적물이 아니라 의도적인 정책이고, auto 모드는 user·policy 스코프에서만 인정되어 프로젝트 설정으로는 옮길 수 없다
- `skillOverrides`로 미사용 스킬 30개를 `"off"` 처리 — 스킬 목록은 컨텍스트에 상주하므로 안 쓰는 항목은 매 세션 비용이다. 되살리려면 해당 키를 지운다
- **사용 이력이 0이어도 살아 있는 스킬이 참조하면 켜 둔다** — 라우팅 대상이 꺼지면 매달린 포인터가 된다. 현재 해당: `fastapi-project-structure`(`python-architecture`가 FastAPI 프로젝트를 넘김), `slides-grab-card-news`(`slides-grab`·`slides-grab-export`가 card-news 덱을 넘김)

> **주의**: `settings.json`에는 `claude-local` clean/smudge 필터가 걸려 있다. 위 변경들은 정상적으로 `git status`·`git diff`에 뜨지만, 머신 로컬 훅 블록(`Stop`·`Notification`·`UserPromptSubmit`)만은 diff에서 제외된다. 그래서 diff의 줄 번호가 실제 파일과 어긋날 수 있다. 단 이 보호는 필터가 등록된 clone에서만 성립한다 (위 경고 참조).
