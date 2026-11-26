# 설치와 운영

이 문서는 [README](../README.md)의 "빠른 시작"을 자세히 풀어 씁니다. 새 머신에 설정을 복원하거나, 설치기가 실패한 항목을 손으로 채우거나, `settings.json` 필터가 무엇을 하는지 알아야 할 때 읽습니다.

## 자동 설치

`scripts/install.sh`는 macOS와 WSL2를 지원하는 대화형 설치기입니다. gum이 있으면 TUI로 선택지를 보여 주고 없으면 일반 입력으로 묻습니다.

| 항목 | 설치 여부 | 하는 일 |
|---|---|---|
| jq | 항상 확인하고 없으면 설치 | 훅 전체가 의존하는 JSON 처리기 |
| ugrep, bfs | 항상 확인하고 없으면 설치 | 셸 스냅샷이 `grep`과 `find`를 이 둘로 바꿔 씀 |
| node, npm | 확인만 함 | statusLine(claude-dashboard)과 slides-grab이 씀 |
| codegraph | 선택 | 심볼 단위 코드 인덱스 MCP. `~/.claude.json`에 전역 등록함 |
| graphify | 선택 | 코드 지식 그래프 CLI |
| slides-grab | 선택 | HTML을 슬라이드 덱으로 만드는 npm 패키지 |
| plannotator | 선택 | 계획 파일을 브라우저에서 리뷰하는 UI. 같은 이름의 플러그인이 씀 |
| 메모리 seed | 확인 후 실행 | `memory-templates/`를 세션 메모리 디렉터리로 동기화함 |
| `settings.json` 필터 | 항상 등록 | 아래 "settings.json 로컬 블록 필터" |
| 마지막 점검 | 항상 실행 | 아래 설명 |

마지막 점검은 설치를 하지 않고 빠진 것을 찾기만 합니다. 설치기는 `settings.json`에서 실제로 등록된 훅과 statusLine 명령을 뽑아 PATH에 있는지, 파일이 있는지, 실행 권한이 있는지 확인합니다. 명령 목록을 설치기에 적어 두지 않고 설정에서 뽑기 때문에 저장소에 없는 머신 로컬 훅도 함께 확인합니다. 추적하는 스킬 9종이 제자리에 있는지도 봅니다. 해결하지 못한 항목은 마지막 요약에 모아 출력합니다.

설치가 끝나면 Claude Code를 재시작합니다. Claude Code가 `enabledPlugins`와 `extraKnownMarketplaces`를 읽어 플러그인을 설치하고, statusLine은 플러그인 캐시가 생긴 뒤에 표시됩니다.

## 수동 설치

설치기를 쓸 수 없으면 아래 순서로 설치합니다. 먼저 의존성의 성격을 확인해 두면 무엇을 빠뜨렸을 때 어떤 증상이 나는지 알 수 있습니다.

| 의존성 | 성격 | 없을 때 |
|---|---|---|
| jq | 필수 | 훅이 오류 없이 동작을 멈춤. 한국어 강제, Python 스타일 안내, CodeGraph 안내, 플로우 정지 규칙이 모두 빠짐 |
| ugrep, bfs | 선택 | 기본 `grep`과 `find`로 동작함. `rules/boundaries.md`의 검색 안내가 전제하는 동작과 달라짐 |
| node | 사실상 필수 | statusLine이 표시되지 않음 |

```bash
# 1. 공통 의존성 (Linux와 WSL2는 sudo apt-get install -y jq ugrep bfs)
brew install jq ugrep bfs

# 2. 선택 도구
uv tool install graphifyy                          # graphify
npm install -g slides-grab                         # slides-grab
curl -fsSL https://plannotator.ai/install.sh | bash  # plannotator
# codegraph는 공식 설치 안내를 따름

# 3. 저장소 복제
git clone https://github.com/otzslayer/my-claude-code-settings.git ~/.claude
cd ~/.claude

# 4. settings.json 필터 등록
git config filter.claude-local.clean  "scripts/git-filter-settings.sh clean"
git config filter.claude-local.smudge "scripts/git-filter-settings.sh smudge"
git config filter.claude-local.required true

# 5. 첫 실행 (플러그인 자동 설치)
claude
```

## settings.json 로컬 블록 필터

`settings.json`에는 grrr 알림 훅처럼 커밋하면 안 되는 훅이 섞여 있습니다. grrr는 macOS 알림을 보내는 CLI이고 이 머신에만 설치되어 있어서 다른 머신에서는 훅이 실패합니다. 그런데 모든 프로젝트에서 알림을 받으려면 이 훅이 `~/.claude/settings.json` 안에 있어야 합니다. Claude Code의 로컬 설정 파일은 언제나 `<프로젝트 루트>/.claude/settings.local.json`이라 사용자 범위에는 로컬 설정을 따로 둘 곳이 없기 때문입니다.

git에는 파일 안의 일부 블록만 추적에서 빼는 기능이 없습니다. 그래서 이 저장소는 `.gitattributes`의 `/settings.json filter=claude-local`과 `scripts/git-filter-settings.sh`로 커밋할 때만 블록을 걷어냅니다.

| 방향 | 동작 |
|---|---|
| clean (작업 트리에서 인덱스로) | `Stop`, `Notification` 이벤트를 통째로 지우고 `UserPromptSubmit`에서는 `grrr`로 시작하는 명령만 지움 |
| smudge (인덱스에서 작업 트리로) | `~/.claude/local-hooks.json`의 내용을 다시 합침 |

`UserPromptSubmit`만 명령 단위로 거르는 이유는 같은 이벤트에 커밋해야 할 `mattpocock-flow.sh`가 함께 있기 때문입니다. 알림 스크립트 `hooks/notify_stop.sh`와 `hooks/notify_noti.sh`는 저장소에 있지만 두 스크립트를 훅으로 등록한 항목은 `local-hooks.json`에만 있습니다.

> **`local-hooks.json`을 지우지 마세요.** 이 파일은 `.gitignore` 대상이고 로컬 훅을 되살리는 유일한 원본입니다. 지우면 다음 checkout 뒤에 알림 훅이 사라집니다. clean이 커밋에서 이 블록을 이미 걷어냈기 때문에 git 이력으로도 되살릴 수 없습니다.

> **clone해도 필터 등록은 복사되지 않습니다.** 필터 설정은 `.git/config`에 저장됩니다. `.gitattributes`는 커밋되지만 필터가 등록되지 않은 clone에서는 git이 경고 없이 원본을 그대로 커밋합니다. `required = true`는 등록된 clone에서 필터 스크립트를 실행하지 못할 때(jq가 없거나 스크립트가 지워졌을 때) 커밋을 실패시키는 장치이지만 등록되지 않은 clone은 보호하지 못합니다. 그래서 clone한 뒤에는 반드시 `install.sh`를 다시 돌리고 `git config --get filter.claude-local.clean`으로 등록을 확인합니다. 결과가 비어 있으면 등록되지 않은 상태입니다.

필터가 걸려 있으면 `git diff settings.json`에 로컬 블록이 나타나지 않습니다. 그래서 diff의 줄 번호가 실제 파일과 어긋날 수 있습니다.

## settings.json 작성 규칙

`settings.json`은 공개 저장소에 들어가므로 어느 머신에서나 그대로 동작하게 씁니다.

- 경로는 절대경로 대신 `$HOME`을 기준으로 씁니다
- `permissions.allow`는 커밋하지 않습니다. Claude Code가 권한을 허락받을 때마다 다시 써 넣는 값이기 때문입니다
- `permissions.defaultMode`는 지정하지 않습니다. Claude Code v2.1.283부터 대화형 세션은 지정하지 않아도 auto 모드로 시작합니다
- 쓰지 않는 스킬은 `skillOverrides`에서 `"off"`로 끕니다. 되살리려면 키를 지웁니다
- 사용 기록이 없어도 다른 스킬에서 작업을 넘겨받는 스킬은 켜 둡니다. 지금은 `fastapi-project-structure`(`python-architecture`가 FastAPI 프로젝트를 넘김)와 `slides-grab-card-news`(`slides-grab`과 `slides-grab-export`가 카드 뉴스 덱을 넘김)가 그렇습니다

## 추적 정책과 스킬 복원

`.gitignore`는 `/*`로 모든 파일을 무시한 뒤 직접 쓴 파일만 `!`로 하나씩 추적에 넣습니다. 그래서 새 파일을 저장소에 넣으려면 `.gitignore`에 경로를 더해야 합니다.

| 경로 | 추적하지 않는 이유 |
|---|---|
| `plugins/` | Claude Code가 관리함 |
| `skills/` (직접 만든 9종 제외) | 플러그인, npm, CLI로 다시 설치할 수 있음 |
| `docs/plans/` | 공개 저장소라 제외함. 계획 파일 삭제 금지 규칙은 그대로 적용되어 작업 트리에만 남음 |
| `memory/`, `projects/` | 머신별 세션 메모리이고 민감한 정보가 있을 수 있음 |
| `settings.local.json`, `local-hooks.json` | 머신 로컬 설정 |
| `sessions/`, `daemon/`, `node_modules/` 등 | 실행 중에 생기는 파일 |

추적하지 않는 스킬은 종류에 따라 다른 방법으로 되살립니다.

| 종류 | 복원 방법 |
|---|---|
| 플러그인 스킬 | Claude Code 재시작 때 자동으로 설치됨 |
| npm 스킬 (`slides-grab`, `slides-grab-*`) | `npm install -g slides-grab` |
| CLI 스킬 (`graphify`) | `uv tool install graphifyy` 뒤 `graphify install --platform claude` |
| 직접 만든 스킬 9종 | clone만으로 복원됨 |

직접 만든 스킬 가운데 `python-coding-style`은 ruff 설정의 원본이고 `fastapi-project-structure/templates/pyproject-template.toml`이 그 설정을 옮겨 쓴 사본입니다. 한쪽을 고치면 다른 쪽도 함께 고칩니다.

## 메모리 seed

Claude Code는 대화에서 배운 사실을 auto memory로 `~/.claude/projects/<host-slug>/memory/`에 저장합니다. `<host-slug>`는 디렉터리 경로의 `/`와 `.`를 `-`로 바꾼 이름입니다. 그래서 `/home/jay/.claude`는 `-home-jay--claude`가 되고 머신마다 홈 경로가 다르면 메모리 디렉터리 이름도 달라집니다. 이 디렉터리를 그대로 추적해서는 다른 머신에 메모리를 옮길 수 없습니다.

`memory-templates/`는 이 문제를 풀려고 둔 디렉터리입니다. 여러 머신에 똑같이 두고 싶은 메모리를 여기에 원본으로 두면 `scripts/sync-memory-templates.sh`가 각 머신의 메모리 디렉터리로 복사합니다.

- `~/.claude/projects/` 아래에서 `<host-slug>` 디렉터리를 찾음. 여러 개면 첫 인자로 받음
- 템플릿 파일이 대상과 같으면 건너뛰고 다르면 diff를 보여 준 뒤 덮어쓸지 물음
- `MEMORY-index.md`의 각 줄을 대상 `MEMORY.md`에 없을 때만 덧붙임

여기에 넣는 메모리는 모든 머신에 공통인 정책과 작업 방식에 대한 피드백입니다. 머신마다 따로 쌓이는 메모리는 넣지 않습니다. 지금은 넣어 둔 메모리가 없고 인덱스 파일(`MEMORY-index.md`)에 주석만 있습니다. 작업 규칙은 이미 `CLAUDE.md`와 `rules/`에 있어서 메모리로 다시 둘 필요가 없기 때문입니다.

```bash
bash ~/.claude/scripts/sync-memory-templates.sh
```
