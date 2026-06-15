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
- rtk (token optimizer) + `rtk init -g` (RTK.md 생성 — 순서 보장)
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
Phase 1: Spec   [Opus·xhigh]   superpowers:brainstorming → docs/superpowers/specs/
Phase 2: Plan   [Opus·xhigh]   /ce-plan → docs/plans/  (Plannotator 게이트)
Phase 2': Build [Sonnet·high]  /ce-work <plan-path>
Phase 3: Ship   [Sonnet·high]  verify → /ce-compound → commit+PR
```

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
