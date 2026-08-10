# my-claude-code-settings

`~/.claude`를 git으로 추적하는 개인 설정 저장소. 개인 멀티머신 백업과 공개를 동시에 지원하도록 설계됐다.

**메인 하네스**: mattpocock-skills (`/ask-matt`가 라우터이자 정본)

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
- **jq** — 컴포넌트 선택과 무관하게 항상 확인·설치한다. `rtk-rewrite.sh` · `settings.json` 인라인 `PreToolUse` 훅 2종(`.py` 편집 시 python-coding-style 주입, `docs/plans/*.md`·`docs/superpowers/specs/*.md` 한국어 강제)이 전부 jq 하드 의존이라, 없으면 이들이 **조용히** 죽는다
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

# jq — 훅 전체의 하드 의존 (rtk-rewrite · settings.json 인라인 훅 2종이
#      모두 조용히 비활성화됨). rtk를 안 써도 필요하다.
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

> **참고**: `skills/`는 원칙적으로 추적하지 않는다(손-작성 스킬 4종 — `capturing-learnings` · `fastapi-project-structure` · `python-architecture` · `python-coding-style` — 만 예외). 플러그인 스킬은 Claude Code가 자동 설치하고, npm/CLI 스킬(slides-grab*, graphify)은 위 2단계에서 직접 설치해야 한다.

---

## Tracking 정책

`.gitignore`는 **provenance allowlist** 방식을 사용한다: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in.

### 추적하는 것

| 항목 | 이유 |
|------|------|
| `CLAUDE.md` | 메인 개발 가이드라인 |
| `settings.json` | 포터블화된 플러그인·훅 설정 |
| `rules/` | 행동 규칙 파일 4종 (boundaries · git-workflow · karpathy-principles · security) |
| `skills/capturing-learnings/` | 회고 스킬 (`SKILL.md` 단일 파일). ce-compound 비활성화로 비어 있던 학습 누적 단계를 대체한다. `docs/solutions/`에 학습 하나를 쓰거나, 판정에서 탈락하면 아무것도 쓰지 않는다 |
| `skills/fastapi-project-structure/` | FastAPI 스캐폴딩 스킬 (템플릿·스크립트·예제·evals). CLAUDE.md 스킬 표에서 직접 호출하는 손-작성 스킬 — 재설치 경로가 없다. `SKILL.md.bak`은 백업 생성물이라 제외 |
| `skills/python-architecture/` | Python 레이어드 아키텍처 스킬 (`SKILL.md` 단일 파일). 위와 같은 이유로 추적 |
| `skills/python-coding-style/` | Python 스타일 규칙 (`SKILL.md` 단일 파일). **ruff 설정의 원본** — `fastapi-project-structure`의 `pyproject-template.toml`이 이걸 인스턴스화하므로 둘은 같이 움직여야 한다 |
| `memory-templates/` | 세션 간 메모리 seed (현재 본문 seed 없음, 인덱스 스캐폴드만) |
| `hooks/*.sh` | rtk-rewrite, graphify-install-check |
| `scripts/sync-memory-templates.sh` | 메모리 템플릿 동기화 |
| `.gitignore`, `.gitattributes`, `README.md` | 저장소 메타 |
| `PRESENTATION.pdf` | 이전 하이브리드 워크플로우 발표자료 (아카이브) |

### 추적하지 않는 것 (기본 무시)

- `plugins/` — Claude Code가 자동 관리, 버전 핀 불필요
- `skills/` — 플러그인·npm이 재설치 가능. 커스텀 수정은 업스트림 회귀 또는 별도 보존. **예외**: `capturing-learnings/` · `fastapi-project-structure/` · `python-architecture/` · `python-coding-style/`는 `.gitignore`에서 명시 opt-in (아래 "스킬 복원 안내")
- `docs/plans/` — **이 저장소만의 예외**. 계획 파일은 삭제 금지 원칙상 프로젝트 저장소에서는 git 추적 대상이지만(`git clean`·머신 이동에서 살아남아야 한다), 여기는 공개 저장소라 무시를 유지한다. 삭제 금지 규칙 자체는 그대로 적용되며 워킹트리에만 존재한다
- `memory/` — 머신별 세션 메모리, 민감 정보 포함 가능
- `node_modules/`, `security/`, `daemon/`, `sessions/` 등 런타임 산출물
- `settings.local.json` — 머신 로컬 override

### 스킬 복원 안내

- **플러그인 스킬** (mattpocock-skills 외 `enabledPlugins`의 활성 항목): Claude Code 재실행 시 자동 복원
- **npm 스킬** (slides-grab, slides-grab-design, slides-grab-export, slides-grab-plan): `npm install -g slides-grab`
- **CLI 스킬** (graphify): `uv tool install graphifyy` 뒤에 `graphify install --platform claude`로 스킬을 배치한다. CLI·`graphify-install-check.sh` 훅(프로젝트에 graphify 훅이 없으면 설치 여부를 묻는다)·스킬이 한 세트로 움직인다. 프로젝트별 설정은 아래 "프로젝트별 설정: CodeGraph · graphify" 참조
- **추적하는 손-작성 스킬** (`capturing-learnings`, `fastapi-project-structure`, `python-architecture`, `python-coding-style`): clone만으로 복원됨. CLAUDE.md 스킬 표(작업 완료 후 학습 기록 / Python 작성 / 새 Python·FastAPI 프로젝트 레이아웃)에서 호출하는 손-콘텐츠라 재설치 경로가 없다. **`python-coding-style`이 ruff 설정의 원본이고 `fastapi-project-structure/templates/pyproject-template.toml`이 그 인스턴스**이므로, 한쪽을 고치면 다른 쪽도 같이 고친다
- **순수 bespoke 스킬** (peon-ping-*, plannotator-annotate 등): 별도 보존 필요 (현재 미추적)

---

## 메인 하네스: mattpocock-skills

워크플로우는 mattpocock-skills로 구성한다. 라우터는 `/ask-matt`이고 그것이 정본이다. `disable-model-invocation: true`라 칠 때만 로드되므로 상주 비용이 0이다.

```
전제  /setup-matt-pocock-skills   프로젝트 저장소에서 1회 (이 저장소는 예외, 아래 참고)
1     /grill-with-docs            인터뷰로 아이디어를 다듬고 CONTEXT.md에 남긴다
2     /prototype                  대화로 안 풀리는 설계 질문이 있을 때만
3     /to-spec → /to-tickets      멀티세션 규모일 때. 티켓마다 blocking edge
4     /implement                  티켓마다, 사이사이 /clear
        └ 내부에서 /tdd 구동, 마무리로 /code-review 후 커밋
```

**자동 라우팅은 없다.** Matt의 메인 플로우 스킬은 전부 `disable-model-invocation: true`라 에이전트가 스스로 켜지 못한다. 라우터도 사용자가 `/ask-matt`를 칠 때만 존재한다. 이전 하네스가 규칙으로 단계를 강제하던 것과 정반대다. 의도한 성질이다.

**`/code-review`는 풀네임으로 부른다.** 접두사 없는 `code-review`는 내장 리뷰 스킬이 차지하고 있다. Matt의 Standards·Spec 2축 리뷰를 쓰려면 `/mattpocock-skills:code-review`라고 쳐야 한다.

**이 저장소에서는 `/setup-matt-pocock-skills`를 돌리지 않는다.** 그 스킬은 저장소 루트의 `CLAUDE.md`를 편집하는데 여기서는 그것이 Tier 0 파일이다. 트래커 미설정 상태에서 `to-tickets`는 로컬 마크다운 경로(`.scratch/<feature>/issues/`)를 지원하고 `wayfinder`도 그것을 기본값으로 쓴다. 다만 `to-spec`에는 폴백 문구가 없어 쓸 때마다 로컬 마크다운으로 간다고 지정해야 한다.

**계획·티켓 산출물.** 새 티켓은 `.scratch/<feature>/issues/<NN>-<slug>.md`로 간다. `.gitignore`가 allowlist 방식이라 자동으로 추적 제외된다. `docs/plans/`의 기존 계획 6개는 legacy로 동결하되 **삭제 금지 규칙은 그대로 유지한다**(`rules/boundaries.md` Never). 변경의 근거 기록이기 때문이다.

**전환 이력.** 2026-08-07에 compound-engineering을 걷어내고 Superpowers 단독으로 수렴했다(`docs/plans/2026-08-07-superpowers-only-harness.md`). 사흘 뒤인 2026-08-10에 Superpowers도 제거했다(`docs/superpowers/specs/2026-08-10-superpowers-removal-design.md`). 두 번째 전환의 근거는 상주 비용이 아니라 실행 비용이었다. 규칙 파일에 이미 있는 내용을 스킬이 다시 로드해 반복하는 층을 걷어냈다. `rules/boundaries.md`·`rules/git-workflow.md`의 규칙 자체는 그대로 남아 있다.

### 모델 · effort

**사용자가 `/model`·`/effort`로 직접 설정한다.** 에이전트는 과업 복잡도를 채점하지 않고 전환을 제안하지도 않는다. 세션 resting 기본값은 `settings.json`의 `effortLevel: high`이고, 모델은 Opus 5다.

서브에이전트 디스패치는 두 갈래다: `Agent` 툴은 `model`만 지정 가능하고 `effort`는 디스패치 세션에서 상속된다. `Workflow`의 `agent()`는 `model`·`effort` 둘 다 개별 지정 가능하다.

### 의존 플러그인

`settings.json`의 `enabledPlugins`가 정본이다. 아래는 `true`인 것들.

| 플러그인 | 역할 |
|---------|------|
| `mattpocock-skills@claude-plugins-official` | 메인 하네스. `/ask-matt`가 라우터 |
| `security-guidance@claude-plugins-official` | 보안 가이드 (보안 리뷰 규칙·security-reviewer) |
| `plannotator@plannotator` | 계획 파일 브라우저 리뷰 (선택 — 강제 게이트 아님) |
| `skill-creator@claude-plugins-official` | 스킬 생성·최적화 |
| `claude-dashboard@claude-dashboard` | statusLine |

**비활성** (`enabledPlugins`에 `false`). 필요하면 `/plugin`으로 되살린다.

| 플러그인 | 내린 이유 |
|---------|------|
| `superpowers@claude-plugins-official` | 걷어낸 이유는 위 "전환 이력" 참고. 종료 두 단계가 `rules/boundaries.md`·`rules/git-workflow.md`와, 훅 case가 `capturing-learnings/SKILL.md`와 내용이 겹쳤다 |
| `compound-engineering@compound-engineering-plugin` | 파이프라인이 Superpowers 단독으로 바뀌었다. `skillOverrides`가 플러그인 스킬을 커버하지 못해(짧은 키·접두사 키 두 형식 모두 실패) `/ce-compound` 하나를 살리려면 쓰지 않는 CE 스킬 23개의 리스팅 비용까지 매 세션 지불해야 했다 — 약 2,400 토큰. 학습 누적은 커스텀 회고 스킬로 대체할 예정 |
| `context7@claude-plugins-official` | 라이브러리 문서 조회 — MCP 호출 기록 0건 |
| `claude-md-management@claude-plugins-official` | CLAUDE.md 감사 — 스킬 1회 사용에 그침 |
| `code-simplifier@claude-plugins-official` | 코드 단순화 — 에이전트 정의만 제공, 호출 0건 |
| `commit-commands@claude-plugins-official` | 커밋·PR. `rules/git-workflow.md`의 규정과 중복 |

### 의존 MCP 서버

MCP 서버 등록은 `~/.claude.json`에 있고 git으로 추적하지 않는다(머신 로컬). 활성:

- `codegraph` — symbol-level code intelligence (`.codegraph/` 인덱스). `install.sh`가 `~/.claude.json`에 전역 자동 등록. 인덱스는 프로젝트마다 `codegraph init`이 따로 필요하다 (아래 "프로젝트별 설정: CodeGraph · graphify")
- `arxiv` — 논문 검색·다운로드 (수동 등록, `read-arxiv-paper` 스킬이 사용)

**비활성** — `disabledMcpServers`로 내렸다. **이 설정은 프로젝트별**이라 다른 프로젝트에서도 끄려면 거기서 `/mcp disable`을 다시 실행해야 한다.

- `sequential-thinking` — 다단계 추론. 호출 기록 0건
- `context7` — 호출 기록 0건. 같은 기능의 `context7@claude-plugins-official` 플러그인도 함께 내렸으므로, 라이브러리 문서 조회를 되살리려면 **둘 중 하나만** 켜면 된다(둘 다 켜면 중복 등록)

> `computer-use`·`claude-in-chrome` 등은 Claude Code 내장/커넥터라 `~/.claude.json`의 `mcpServers`에 없다.

---

## 프로젝트별 설정: CodeGraph · graphify

두 도구의 사용 지침은 **전역 `CLAUDE.md`에 두지 않는다.** 대부분의 저장소에는 인덱스가 없어서 전역 서술이 죽은 무게이거나 아예 거짓이 된다(걷어낸 graphify 섹션은 "This project has a knowledge graph at graphify-out/"라고 단정하고 있었다). 실제로 쓰는 프로젝트에서 그 프로젝트의 `CLAUDE.md`가 갖는다.

전역에 남은 것은 도구를 쓸 상황인지 판정하는 장치뿐이다.

- `settings.json`의 SessionStart·PreToolUse 훅 3종이 `.codegraph/` 존재를 검사해 CodeGraph 안내를 조건부로 주입한다
- `hooks/graphify-install-check.sh`가 프로젝트에 graphify 훅이 없으면 설치 여부를 묻고, 거절하면 `.claude/.graphify-skip`을 남겨 같은 프로젝트에서 다시 묻지 않는다
- `rules/boundaries.md`는 MCP `initialize` 지침에 없는 두 가지(`codegraph status`, CLI 단독 서브도구)만 언급한다

### CodeGraph

```bash
cd <프로젝트 루트>
codegraph init              # .codegraph/ 인덱스 생성 (데몬이 파일 변경을 실시간 반영)
codegraph install -l local  # ./.mcp.json + ./.claude/settings.json 에 프로젝트 스코프 등록
```

`install.sh`는 `~/.claude.json`에 MCP 서버를 **전역** 등록한다. 전역 등록만 있으면 도구는 붙지만 인덱스가 없어 답을 못 하므로 프로젝트마다 `codegraph init`이 따로 필요하다. `-l local`은 그 프로젝트에서만 MCP를 붙이고 싶을 때 쓴다. 인덱스 상태는 `codegraph status`로 본다.

**사용법을 프로젝트 `CLAUDE.md`에 옮겨 적을 필요는 없다.** MCP 서버가 `initialize`로 직접 보낸다. codegraph도 issue #529 이후 `CLAUDE.md` 블록을 쓰지 않는다(`installer/config-writer.js` 주석에 명시). 이전 전역 `CLAUDE.md`의 `<!-- CODEGRAPH_START -->` 블록은 구버전 잔재였다.

### graphify

```bash
cd <프로젝트 루트>
graphify install --project --platform claude
graphify update .           # 초기 그래프 생성 (AST 전용, API 비용 없음)
```

`--project`가 프로젝트 `.claude/settings.json`에 PreToolUse 훅을 등록한다. 훅 커맨드에 `graphify-out` 경로가 들어가고, `graphify-install-check.sh`는 그 문자열 존재로 설치 여부를 판정한다(권한 항목의 단순 `graphify` 언급 오탐을 피하려는 설계). `--strict`를 더하면 세션당 첫 원본 파일 읽기를 `graphify query` 한 번이 돌기 전까지 막는다.

graphify는 MCP가 아니라 CLI라서 지침이 자동으로 도착하지 않는다. 트리거는 전역 설치된 `graphify` 스킬과 위 프로젝트 훅이 담당하지만, `graphify-out/` 산출물별 사용 규칙은 프로젝트 `CLAUDE.md`에 직접 적는다. 붙여 쓸 최소 형태:

```markdown
## graphify

이 프로젝트에는 `graphify-out/`에 지식 그래프가 있다.

- 코드베이스 질문은 `graphify query "<질문>"`을 먼저 실행한다. 관계는 `graphify path "<A>" "<B>"`, 개별 개념은 `graphify explain "<개념>"`. 셋 다 스코프가 좁혀진 서브그래프를 돌려주므로 `GRAPH_REPORT.md`나 raw grep보다 작다
- `graphify-out/wiki/index.md`가 있으면 원본 탐색 대신 이걸로 훑는다
- `graphify-out/GRAPH_REPORT.md`는 전체 아키텍처 검토나 위 세 명령이 부족할 때만 읽는다
- 코드를 고친 뒤 `graphify update .`로 그래프를 갱신한다
```

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
