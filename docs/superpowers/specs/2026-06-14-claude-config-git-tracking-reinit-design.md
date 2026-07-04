# `~/.claude` git tracking 재정립 — 설계

**날짜**: 2026-06-14
**상태**: 검토 대기 (사용자 승인 게이트)
**대상 repo**: `~/.claude` (remote: `github.com/otzslayer/my-claude-code-settings`)

> 참고: 이 repo는 정책상 `docs/`를 추적하지 않는다(아래 §4). 따라서 이 spec은 **이번 작업용 임시 계획 문서**이며, 영구 기록은 재작성될 `README.md` + `.gitignore`다.

---

## 1. 목표와 제약

- **목적**: "둘 다" — 개인 멀티머신 백업 + 공개 가능. → 가장 엄격한 기준 적용:
  - 시크릿/머신-로컬은 **항상** 추적 제외
  - 경로는 `$HOME` 기반(하드코딩 `/Users/jayhan` 금지)
  - **출처가 이 폴더인 손-콘텐츠만** 추적
- **실행 방식**: history 유지하지 않고 **fresh `git init`** (새 출발). 기존 커밋 기록은 버린다. remote는 **force-push**(사용자 승인됨).
- **플랫폼**: macOS와 **WSL2 양쪽에서 무탈 동작**. 경로·패키지 매니저·sed/line-ending 차이를 install.sh와 `.gitattributes`가 흡수한다.
- **핵심 인사이트**: `~/.claude`가 곧 `my-claude-code-settings` repo다(별도 정본 repo 없음). 따라서 **여기서 추적하지 않는 bespoke 콘텐츠는 새 머신에서 영구 소실**된다. 이 제약이 "무엇을 추적 안 할지"의 안전망 기준이 된다.

> **📦 Plan 분리 (사용자 결정)**: 비가역 git 작업을 불확실한 설치기 빌드에 묶지 않기 위해 **두 플랜으로 분리**한다.
> - **Plan A (코어 tracking 재정립 — 먼저 ship)**: §2~§7, §9~§12. allowlist `.gitignore`/`.gitattributes` + fresh init + `settings.json` 포터블화(permissions 제거) + 스킬 안전망 + README(수동 설치 안내) + 스윕 + force-push.
> - **Plan B (gum 설치기 — 후속 `/ce-plan`)**: §8. gum TUI 설치기 + 툴 설치처 확정(R7) + README 설치 섹션 보강 + permissions strip pre-commit 가드(옵션).
>
> 이 spec은 두 플랜을 **모두 설계**하지만, 실행은 Plan A → (검증/ship) → Plan B 순서다.

---

## 2. 핵심 원칙 — provenance 기반 allowlist

> **추적** = 출처가 이 폴더인 손-콘텐츠 (이 repo가 유일한 upstream)
> **무시** = 런타임 산출물 · 외부 설치물(업스트림 있음) · 머신-로컬/시크릿

`.gitignore`는 **allowlist**: `/*`로 전부 무시한 뒤 손-콘텐츠만 `!`로 opt-in. 런타임이 새 디렉토리를 만들어도 기본이 무시라 노이즈가 다시 새지 않고, 미지 파일이 기본 무시되니 시크릿도 자동 보호된다. ("정신없어진" 근본 원인 = denylist가 런타임 산출물 경주에서 계속 짐 → allowlist로 차단.)

---

## 3. 최종 추적 대상 (allowlist)

188개 → **핵심 코어만** 남긴다.

| 추적 항목 | 성격 | 비고 |
|---|---|---|
| `.gitignore` | allowlist 정의 | |
| `README.md` | 설치 가이드 + 정책 | **대대적 재작성**(§7) |
| `CLAUDE.md` | 글로벌 행동 규칙 (bespoke) | `@RTK.md` import 의존성 주의(§6) |
| `rules/` | 행동 규칙 5종 (bespoke) | boundaries·karpathy·git-workflow·security·hybrid-workflow |
| `settings.json` | 글로벌 설정 단일 파일 (포터블화) | §9 — local 분리 없음 |
| `hooks/*.sh` | bespoke 훅 3종 | rtk-hook·rtk-rewrite·workflow-stage-inject (peon-ping/ 제외) |
| `memory-templates/` | seed 메모리 (bespoke) | §6 sync 메커니즘과 페어 |
| `scripts/sync-memory-templates.sh` | seed 동기화 도구 | memory-templates/와 페어 — **유지** |
| `scripts/install.sh` | **신규** gum 기반 TUI 설치기 | §8 — **Plan B 산출**(allowlist는 미리 opt-in) |
| `.gitattributes` | line-ending 강제(`*.sh eol=lf`) | **신규** — WSL2 CRLF 방지 |

---

## 4. 무시 대상 (allowlist라 자동 — 명시 확인용)

| 카테고리 | 항목 | 사유 |
|---|---|---|
| 런타임/캐시 | `node_modules/`, `security/`, `daemon/`, `jobs/`, `sessions/`, `.codegraph/`, `statusline-output/`, `chrome/`, `plugins/`, `projects/`, `memory/`, `.last-*`, `mcp-needs-auth-cache.json`, `claude-devtools-notifications.json`, `.DS_Store`, `session-report-*.html` | 재생성됨 |
| 머신-로컬/시크릿 | `settings.local.json`, `*.local.json`, 중첩 `.claude/` | 머신 종속/사고 산출물 |
| 백업 잔해 | `*.bak`, `settings.json.bak*`, `backups/` | 정리 대상 |
| 외부 설치물 | `skills/` **전체**, `RTK.md`, `package.json`/`package-lock.json`, `agents/`, `contexts/`, `docs/`, `commands/`, `translate-doc-assets/`, `tag-doc-assets/`, `TODO.md`, `scripts/sync-claude-to-codex.sh`, `scripts/generate-agents-md-from-claude.sh` | 아래 결정 근거 |

### 결정 근거 (피드백 반영)

- **`skills/` 전체 미추적** — 설치/재현으로 복원(§5 안전망). slides-grab*(npm), impeccable(플러그인), deep-research/project-planner/technical-writer(awesome-llm-apps), 그 외 큐레이션 import. **단, 안전망 검증 필수.**
- **`RTK.md`** — `rtk init -g`로 생성됨 → 미추적, install.sh가 재생성(§6).
- **`package.json`/`lock`** — slides-grab npm 의존성 때문에만 존재. slides-grab은 자체 설치 → install.sh가 담당, 추적 불필요.
- **`agents/`** — 어디서도 실제 참조 안 됨(매칭은 전부 오탐). ce-*/superpowers 에이전트로 대체됨 → 레거시, 드롭.
- **`contexts/`** — 참조 0 → 레거시, 드롭.
- **`commands/`(translate-doc·tag-doc)** — 사적 워크스페이스(`/Users/jayhan/workspaces/translate-with-gpt/...`)에 강결합된 per-user 번역 툴링 → **미추적**(translate-doc-assets/ 미추적 결정과 일관). PII 차단도 겸함.
- **`docs/`, `translate-doc-assets/`, `tag-doc-assets/`, `TODO.md`** — 사용자 지시(불필요/per-user).
- **`scripts/` 중 codex 동기화 2종** — Codex 미사용 → 드롭. `sync-memory-templates.sh`만 유지.

---

## 5. `skills/` 미추적 + 안전망

사용자 결정: "skills는 추적 안 함, 필요하면 알아서 설치." 단 §1의 제약(이 repo가 유일한 보금자리)상 **업스트림 없는 bespoke 스킬은 미추적 시 영구 소실**된다.

**정책**: 기본 미추적 + **구현 단계 2축 안전망 검증** (출처 **및** divergence)

진짜 소실 조건은 "업스트림 없음"만이 아니라 "업스트림 있으나 **내가 수정함**"이다 — 후자는 재설치로 덮여 커스터마이즈가 조용히 사라진다(README changelog가 `fastapi-project-structure`·`senior-architect`·`python-testing-patterns` 수정을 기록, `git status`에 `M skills/graphify/SKILL.md`). 따라서:

1. 구현 시 `skills/`의 각 디렉토리에 대해 (a) 업스트림 출처(npm/플러그인/공개 컬렉션 마커: `author:`, `.graphify_version`, 플러그인 네임스페이스 등)와 (b) **divergence**(fresh 설치본과 diff)를 함께 확인한다.
2. 출처 **확인 + 미수정** → 미추적. install.sh에 설치 커맨드 기록.
3. 출처 **없음**(순수 bespoke) **또는** 출처 **있으나 수정됨**(diverged) → 사용자에게 **목록 보고**. 침묵 드롭 금지. 사용자가 (a) 예외로 추적 또는 (b) 폐기/업스트림 회귀 선택.

> translate-doc/tag-doc은 `commands/`에 있으나 **미추적**(§4 — 사적 워크스페이스 결합). 이 안전망 정책은 `skills/`에만 적용된다.

---

## 6. seed 메모리 메커니즘 (`memory-templates/` + `sync-memory-templates.sh`)

사용자가 잊고 있던 페어다. 동작:
- live 메모리(`projects/<slug>/memory/`)는 gitignored → 백업 안 됨.
- `memory-templates/`는 **버전 관리되는 seed**. `sync-memory-templates.sh`가 이를 live 메모리로 idempotent 동기화(diff 후 `[y/N/s]` prompt, host-local 메타 노이즈 정규화).
- → "새 머신에서 큐레이션한 메모리 복원"이 가능해짐. **"둘 다(백업)" 목적에 정확히 부합 → 유지 권장.**
- 현재 seed는 `feedback_hybrid_workflow.md` 1개뿐. live엔 translate_doc_glossary·term_preferences 등이 더 있음 → 백업하려면 seed에 추가 필요(후속, 이번 범위 밖이나 README에 안내).

**RTK.md 의존성**: `CLAUDE.md`가 `@~/.claude/RTK.md`와 `@RTK.md`를 import. RTK.md는 미추적이라 fresh 머신엔 없음 → **install.sh가 rtk 설치 후 `rtk init -g`를 먼저 실행**해야 CLAUDE.md가 깨지지 않음(설치 순서 제약).

---

## 7. `README.md` 재작성 범위

현 README는 stale(`model:haiku`(실제 opus), "13 agents", 옛 스킬 수치, 추적되지 않을 디렉토리 구조 설명). 재작성:
- **설치 가이드**: **Plan A** — clone → 수동 설치 단계 문서화. **순서 명시 필수**: ① `rtk` 설치 → `rtk init -g`(RTK.md 생성, **이전엔 CLAUDE.md의 `@RTK.md` import가 깨짐**) → ② 나머지 툴(codegraph·graphify·slides-grab) → ③ Claude Code 첫 실행 시 플러그인 자동 설치 + statusLine 점등(플러그인 캐시 생성 후). **Plan B** — `scripts/install.sh` 원클릭 섹션으로 대체/보강.
- **tracking 정책**: 무엇을 왜 추적/무시하는지(provenance allowlist 설명).
- **hybrid-workflow가 메인**임을 명시 + 그것이 의존하는 플러그인·툴 목록.
- 낡은 수치/구조도 제거.

---

## 8. `scripts/install.sh` — gum 기반 크로스플랫폼 TUI 설치기 `[Plan B]`

`rules/hybrid-workflow.md`가 **macOS·WSL2** fresh 머신에서 동작하도록 의존 플러그인·툴을 인터랙티브 설치. **린하게** 유지 — gum 선택 UI + idempotent 설치 + 정직한 수동 폴백. 프레임워크화 금지(YAGNI).

**실행 흐름**:
1. **플랫폼 감지** — `uname -s`(Darwin/Linux) + WSL2(`grep -qi microsoft /proc/version`). 패키지 매니저·경로 분기 결정.
2. **gum bootstrap** — `command -v gum` 없으면: macOS `brew install gum` / Linux·WSL2 charm apt repo 또는 release 바이너리 → `~/.local/bin`. 실패 시 **plain `read` 폴백**. 선택 헬퍼(`choose()`/`confirm()`)가 gum 유무를 추상화해 본문 중복 없이 양쪽 지원.
3. **컴포넌트 멀티셀렉트**(`gum choose --no-limit`) — rtk·codegraph·graphify·slides-grab. 합리적 기본 체크. (**peon-ping은 하네스 비포함** — 개인 로컬 사운드 취향이므로 설치기에서 제외.)
4. **툴별 설치**(idempotent — `command -v` 스킵, `gum spin` 진행표시):
   - `rtk` → macOS `brew install` (정확한 tap 확인 필요, R7) / WSL2 release·cargo (이름 충돌 회피, R7). 설치 후 `rtk gain`으로 충돌 검증.
   - `graphify` → `uv tool install graphifyy` (양 플랫폼 동일).
   - `codegraph` → 공식 인스톨러 one-liner (확인 필요, R7).
   - `slides-grab` → `npm i -g slides-grab` (이후 자체 skill provision).
   - `node`/`npm`/`uv` 선행 부재 시 감지·안내. 자동설치는 uv만(`curl -LsSf https://astral.sh/uv/install.sh | sh`); node는 플랫폼별 안내(brew / nvm / apt).
5. **RTK.md 생성** — rtk 설치 후 `rtk init -g` (CLAUDE.md `@RTK.md` 의존 → 순서 필수, R4).
6. **플러그인** — `settings.json`의 `enabledPlugins`+`extraKnownMarketplaces` 확인 → Claude Code 로드 시 설치(문서화), 가능하면 트리거.
7. **seed 메모리**(토글) — `scripts/sync-memory-templates.sh` 실행.
8. **요약 + 수동 단계 출력** — 자동화 불가 항목(MCP/플러그인 헤드리스 한계 등)을 명확히 안내. **조용한 실패 금지.**

> settings는 별도 단계가 없다 — 포터블화된 `settings.json`이 clone으로 도착해 동작하고, user-level local 파일은 존재하지 않는다(§9.1).

**크로스플랫폼 흡수**:
- 경로: `command -v`로 해석, 하드코딩 금지(`/opt/homebrew` vs `/home/linuxbrew`).
- line-ending: `.gitattributes`로 `*.sh text eol=lf` 강제 → WSL2에서 CRLF 깨짐 방지.
- sed: BSD/GNU 차이 회피(필요 시 `LC_ALL=C` — `sync-memory-templates.sh` 선례).

---

## 9. `settings.json` 처리 — 단일 추적 파일을 포터블화 (공식 문서 정정)

**정정 (공식 문서 확인 — code.claude.com/docs/en/settings)**: Claude Code는 **user(글로벌) 스코프에 `settings.local.json`을 두지 않는다.** `settings.local.json`은 **프로젝트 전용**(`<proj>/.claude/settings.local.json`)이다. 글로벌(`~/.claude`)엔 **`settings.json` 하나뿐**이며 이것이 모든 프로젝트에 적용된다. precedence: managed > CLI > project-local > project > **user(`~/.claude/settings.json`)**.

→ "spine/local 분리"(이전 설계)는 **글로벌 레벨에서 성립하지 않는다**. 글로벌 hook/env를 (존재하지 않는) user-level local로 옮기면 **읽히지 않아 전역 적용이 깨진다**(사용자 지적이 정확). 따라서 모든 글로벌 설정은 **추적되는 `~/.claude/settings.json` 하나에** 남기고, 머신/PII 차이는 **파일을 옮기지 않고 포터블화**로 흡수한다. (기존 `~/.claude/settings.local.json`은 레거시/stray — gitignore.)

**추가 확정 (동일 문서)**: 글로벌 "always allow" **permissions도 `~/.claude/settings.json`에 기록**되며, 글로벌 **hooks도 거기에만** 둘 수 있다(gitignored 대안 없음). 즉 permissions를 공개에서 빼려면 **파일에서 비우는 수밖에 없고**, Claude가 이후 grant를 다시 써넣으므로 **유입 방지 가드**(§10-10 스윕 확장 + Plan B pre-commit 옵션)가 필요하다.

**처리 = 단일 `settings.json`을 포터블·sanitize** (hook·statusLine은 shell command라 `$HOME`·command-substitution 확장됨):

| 항목 | 처리 |
|---|---|
| `/Users/jayhan` 3곳 (L58·L206 hook, L228 statusLine) | `$HOME`로 교정. 대부분 hook은 이미 `$HOME` 사용 중 |
| `statusLine` 버전 핀(`.../1.29.0/...`) | `node "$(ls -td "$HOME"/.claude/plugins/cache/claude-dashboard/claude-dashboard/*/ \| head -1)dist/index.js"` glob화. 바이너리도 `node`(PATH) → WSL2 호환 |
| peon-ping 훅 블록 | **제거**(하네스 비포함). 개인이 원하면 clone 후 직접 추가(git에 modified로 뜸 — 감수) |
| `permissions` | **제거**(사용자 결정). user-level 숨길 곳 없음 → 파일에서 비움. 초기 커밋은 깨끗이 author, 이후 Claude가 grant를 재기입하므로 §10-10 스윕이 permissions 블록도 검사(가드). Plan B에서 pre-commit strip 훅 옵션 |
| `env`·`enabledPlugins`·`extraKnownMarketplaces`·`skills`·`enableWorkflows`·`skillListingBudgetFraction` | 추적 유지 — 공유 wiring·전역 env |
| `model`·`effortLevel`·`language`·`advisorModel`·`tui`·`agentPushNotifEnabled` | **추적 유지**(공개 OK·비민감, 사용자 결정 — 공개하되 permissions만 제외) |

> ⚠️ **permissions 제외의 지속 비용 (사용자 인지 필요)**: 추적 파일=live 파일이라, 초기 커밋은 깨끗해도 이후 Claude가 grant를 `settings.json`에 다시 써넣는다. → settings.json이 **상시 dirty 상태**가 되고 **매 커밋마다 재유입 위험**이 생긴다. Plan A의 초기 push는 안전(§10-10 스윕)하지만, 이 지속 마찰을 **지금 의식적으로 수용**해야 한다. Plan B에서 가드(① `git update-index --skip-worktree settings.json` — 단순, clone마다 재실행 / ② pre-commit JSON-strip 훅 — Claude 쓰기와 싸워 더 취약) 중 택1. 어느 쪽이든 §10-10 스윕이 핵심 안전망.

### 9.1 설치 시 settings.json 메커니즘 (사용자 질문 답)

**설치기는 `settings.json`을 편집하지 않는다.** 포터블화된 단일 파일이 `git clone`으로 **그대로 도착**해 즉시 동작한다. 머신별 차이(statusLine 버전 경로 등)는 command-substitution glob이 **런타임에 흡수**하므로 설치기 개입이 불필요하다. 플러그인은 설치기가 아니라 **Claude Code가 로드 시 `enabledPlugins`+`extraKnownMarketplaces`를 읽어** 마켓플레이스에서 설치한다(설치기는 "재시작하면 깔린다" 안내만). → user-level local 파일이 없으므로 "settings에 내용 추가"라는 단계 자체가 없다.

### 9.2 hooks 설정 처리 (사용자 질문 — 상세)

hooks는 글로벌 와이어링이므로 **추적되는 `settings.json`의 `hooks` 블록 안에 그대로 둔다**(= 공개됨, 의도된 것 — hooks가 곧 공유하려는 하네스). user 레벨엔 gitignored 대안이 없어 이 위치가 강제된다.

| hook (matcher) | 명령 | 처리 |
|---|---|---|
| PreToolUse:`Bash` | `$HOME/.claude/hooks/rtk-hook.sh` + `rtk-rewrite.sh` | **유지** — L58 `/Users/jayhan`→`$HOME` 교정 |
| PreToolUse:`Edit\|Write` | 인라인 `jq`(python-coding-style 리마인더) | **유지**(외부 파일 없음) |
| PostToolUse:`ExitPlanMode` | 인라인 `echo`(plan 승인→docs/plans 가이드) | **유지**(인라인) |
| PostToolUse:`Skill` | `$HOME/.claude/hooks/workflow-stage-inject.sh` | **유지** — L206 `/Users/jayhan`→`$HOME` 교정 |
| SessionStart·UserPromptSubmit·Stop·Notification·PermissionRequest·SessionEnd·SubagentStart·PostToolUseFailure·PreCompact | `$HOME/.claude/hooks/peon-ping/peon.sh` 등 | **전부 제거**(peon-ping 하네스 비포함) |

- 참조 스크립트 `hooks/rtk-hook.sh`·`rtk-rewrite.sh`·`workflow-stage-inject.sh`는 **추적**(allowlist `!/hooks/*.sh`) → clone하면 훅+스크립트가 함께 도착.
- 새 머신 동작: clone 직후 인라인 훅(jq/echo)은 바로 동작. rtk 훅은 Plan B 설치기가 `rtk` 설치 후 동작(미설치 시 훅이 에러하나 Claude Code는 hook 실패를 tolerate).

---

## 10. 실행 계획 (fresh init) `[Plan A]`

1. (사전) 현 작업트리 백업 권장(`backups/`는 어차피 미추적).
2. `rm -rf .git` → `git init`.
3. 새 allowlist `.gitignore` + `.gitattributes`(`* text=auto`, `*.sh text eol=lf`) 작성(§11).
4. `settings.json` 포터블화/sanitize(§9: `/Users/jayhan`→`$HOME`, statusLine glob화+`node` PATH, peon-ping 훅 제거). **user-level local 분리 안 함**(존재하지 않음).
5. **PII 정규화 확인**: `commands/`는 미추적이라 translate-doc 사적 경로는 자동 제외. settings.json 외 추적 셋에 잔여 절대경로 없는지 §10-10 스윕으로 검증.
6. README 재작성(§7 — **Plan A는 수동 설치 안내**). `scripts/install.sh`는 **Plan B**에서 작성.
7. §5 안전망: 미추적 스킬 출처+divergence 검증 → bespoke/diverged 잔여 보고.
8. **allowlist 실증 검증**: `git check-ignore -v`로 sentinel 확인(`settings.local.json`, `hooks/peon-ping/x`, `skills/x`, `node_modules/x`는 **무시**돼야; `CLAUDE.md`, `hooks/rtk-hook.sh`는 **추적**돼야). 패턴을 눈으로만 믿지 않는다.
9. `git add` → 추적 셋 확인(`git status`).
10. **🔒 필수 게이트 — 공개 push 전 전체 시크릿/PII 스윕**: staged 전체를 **RTK 우회**(`rtk proxy grep ...`)로 스캔(시크릿·`/Users/jayhan`·이메일·머신명). **+ `settings.json`에 `permissions` 블록이 비었는지 확인**(사용자 결정 — 공개 제외). RTK가 grep 출력을 필터해 매치를 숨길 수 있으므로 raw 실행 필수. 깨끗함 확인 후에만 진행.
11. initial commit(한국어 커밋 포맷).
12. remote 연결 + **force-push**(remote history 덮어씀 — **사용자 승인됨**).

> ⚠️ **force-push 경고**: remote `otzslayer/my-claude-code-settings`의 기존 history가 사라진다(사용자 승인됨). §10-10 스윕 통과가 선결 조건.

---

## 11. allowlist `.gitignore` (검토 대상 — 사용자 최종 승인)

```gitignore
# ~/.claude — allowlist .gitignore
# 기본: 전부 무시. 손-콘텐츠만 명시적으로 opt-in.
/*
!/.gitignore

# --- 루트 손-파일 ---
!/.gitattributes
!/README.md
!/CLAUDE.md
!/settings.json

# --- 손-콘텐츠 디렉토리 (전체 포함) ---
!/rules/
!/memory-templates/

# --- hooks: 손-스크립트(*.sh)만, 플러그인 하위 제외 ---
!/hooks/
/hooks/*
!/hooks/*.sh

# --- scripts: 선별 2종만 ---
!/scripts/
/scripts/*
!/scripts/sync-memory-templates.sh
!/scripts/install.sh
```

이 패턴의 결과:
- `settings.local.json`, `node_modules/`, `skills/`, `agents/`, `contexts/`, `docs/`, `RTK.md`, `package*.json`, `*-assets/`, `*.bak`, 중첩 `.claude/`, 모든 런타임 디렉토리 → **자동 무시**.
- `hooks/peon-ping/` → `/hooks/*`에 걸려 무시(`.sh`만 통과).
- `scripts/sync-claude-to-codex.sh` 등 → opt-in 안 했으므로 무시.

---

## 12. Open items / 리스크

- **(R1) bespoke 스킬 소실 위험** — §5 안전망으로 완화. 구현 시 출처 미확인 스킬 반드시 보고.
- **(R2) install.sh 자동화 한계** — MCP/플러그인 헤드리스 설치 제약. 수동 단계 명시로 완화.
- **(R3) force-push 비가역성** — §10-12. **사용자 승인됨**.
- **(R4) RTK.md import 순서** — install.sh에서 rtk init 선행(§6).
- **(R5) hybrid-workflow.md의 stale 경로** — spec 출처를 `~/my-claude-code-settings/...`로 가리킴(실제 `~/.claude/...`). 이번 범위 밖이나 후속 정정 권장.
- **(R6) seed 메모리 미완** — live 메모리 일부만 seed화됨. README에 "백업하려면 seed 추가" 안내.
- **(R7) rtk·codegraph 크로스플랫폼 설치 출처 미확정** — 구현 시 확정. rtk는 이름 충돌(RTK.md) 회피 + `rtk gain` 검증, codegraph는 공식 one-liner 확인. graphify(`uv tool install graphifyy`)·slides-grab(npm)은 확정.
- **(R8) ~~peon-ping WSL2 오디오~~ (해소)** — peon-ping은 하네스 비포함(설치기 제외, settings.json 훅 제거)으로 결정 → 리스크 소멸. 개인이 자기 머신에서 별도 운용.
- **(R9) CRLF/line-ending** — Windows에서 편집 시 `.sh`가 CRLF로 깨질 위험. `.gitattributes`의 `* text=auto`, `*.sh text eol=lf`로 완화.
- **(R10) gum bootstrap 실패** — 네트워크/권한 부재 시 gum 설치 불가. plain `read` 폴백 경로를 항상 유지(선택 헬퍼 추상화).
- **(R11) 추적 셋 PII 누출(실측)** — `commands/translate-doc.md`의 사적 워크스페이스 경로는 **commands/ 미추적으로 해결**. 잔여는 `settings.json` 3곳뿐 → §10-4 포터블화로 차단. 공개 push 전 §10-10 스윕으로 최종 확인.
- **(R12) RTK가 보안 스윕을 오염** — rtk-hook이 `grep` 출력을 필터해 매치를 숨길 수 있음(실측 확인). §10-10 스윕은 반드시 `rtk proxy`로 RTK 우회 실행.
- **(R13) force-push는 old remote history를 정화하지 못함 (실측: repo 이미 PUBLIC)** — remote는 **2026-02-17부터 public, 46개 커밋**. fresh init+force-push는 새 HEAD만 깨끗하게 하고, **과거 46개 커밋은 SHA로 도달 가능**하게 남는다(fork·캐시·인덱싱). 파일명 스캔상 시크릿 이름 파일은 과거에도 없음(✓), 그러나 `/Users/jayhan` 경로·username은 **이미 과거 커밋에 노출됨**(저심각도 PII, 시크릿 아님). → **사용자 결정: (a) 과거 노출 수용** (저심각도 — username·로컬 경로, 시크릿 아님). force-push로 새 HEAD만 정리, 과거 46개 커밋은 그대로 둔다. repo 삭제·재생성 안 함.
- **(R14) Plan A 단독 clone의 깨진 import** — RTK.md 미추적이라 fresh Plan-A clone은 `rtk init -g` 전까지 CLAUDE.md `@RTK.md`가 깨짐. §7 README가 rtk 설치→init을 **최우선 단계로** 명시해 완화.
