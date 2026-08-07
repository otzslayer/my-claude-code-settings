#!/usr/bin/env bash
# install.sh -- ~/.claude 워크플로우 의존 툴 인터랙티브 설치기
#
# 지원: macOS (brew) / WSL2 (apt/release binary)
# TUI:  gum (없으면 plain read 폴백)
# 순서: 플랫폼 감지 -> gum bootstrap -> 컴포넌트 선택 -> 전제 확인 ->
#        툴 설치 -> RTK.md 생성 -> 메모리 seed -> settings.json 로컬 블록 필터 ->
#        훅·의존성 점검 -> 요약

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# 훅·statusLine 점검 대상 설정 파일.
# 저장소를 ~/.claude로 clone하는 것이 정식 경로이므로 라이브 설정이 우선이고,
# 다른 위치에서 실행했을 때만 저장소 사본으로 폴백한다.
SETTINGS_FILE="$HOME/.claude/settings.json"
[[ -f "$SETTINGS_FILE" ]] || SETTINGS_FILE="$REPO_ROOT/settings.json"

# ---------------------------------------------------
# 0. 플랫폼 감지
# ---------------------------------------------------
OS="$(uname -s)"
IS_WSL=false
if [[ "$OS" == "Linux" ]] && grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=true
fi

if [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macOS"
elif [[ "$IS_WSL" == "true" ]]; then
    PLATFORM="WSL2"
else
    PLATFORM="Linux"
fi

echo "플랫폼 감지: $PLATFORM"
echo

# ---------------------------------------------------
# 1. gum bootstrap (없으면 설치, 실패 시 plain read 폴백)
# ---------------------------------------------------
GUM_OK=false
if command -v gum &>/dev/null; then
    GUM_OK=true
else
    echo "gum이 없습니다. 설치를 시도합니다..."
    if [[ "$PLATFORM" == "macOS" ]]; then
        if brew install gum 2>/dev/null; then
            GUM_OK=true
        fi
    else
        # WSL2/Linux: charm apt repo 시도
        if command -v apt-get &>/dev/null; then
            if (
                sudo mkdir -p /etc/apt/keyrings
                curl -fsSL https://repo.charm.sh/apt/gpg.key \
                    | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
                echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
                    | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
                sudo apt-get update -qq
                sudo apt-get install -y gum
            ) 2>/dev/null; then
                GUM_OK=true
            fi
        fi

        # 실패 시 release binary fallback
        if [[ "$GUM_OK" == "false" ]]; then
            GUM_VERSION="0.14.3"
            case "$(uname -m)" in
                x86_64)   GUM_ARCH="x86_64" ;;
                aarch64)  GUM_ARCH="arm64" ;;
                *)        GUM_ARCH="x86_64" ;;
            esac
            GUM_URL="https://github.com/charmbracelet/gum/releases/download/v${GUM_VERSION}/gum_${GUM_VERSION}_Linux_${GUM_ARCH}.tar.gz"
            LOCAL_BIN="$HOME/.local/bin"
            mkdir -p "$LOCAL_BIN"
            if curl -fsSL "$GUM_URL" | tar xz -C "$LOCAL_BIN" --wildcards --no-anchored 'gum' 2>/dev/null; then
                export PATH="$LOCAL_BIN:$PATH"
                command -v gum &>/dev/null && GUM_OK=true
            fi
        fi
    fi

    if [[ "$GUM_OK" == "true" ]]; then
        echo "gum 설치 완료."
    else
        echo "gum 설치 실패 -- plain read 폴백으로 진행합니다."
    fi
fi

# ---------------------------------------------------
# 헬퍼: spin / confirm / warn / ok / skip
# ---------------------------------------------------

spin() {
    # spin <message> <cmd...>
    local msg="$1"; shift
    if [[ "$GUM_OK" == "true" ]]; then
        gum spin --spinner dot --title "$msg" -- "$@"
    else
        echo "$msg"
        "$@"
    fi
}

confirm() {
    # confirm <message> -- 0=yes 1=no
    local msg="$1"
    if [[ "$GUM_OK" == "true" ]]; then
        gum confirm "$msg" && return 0 || return 1
    else
        local ans
        read -rp "$msg [y/N] " ans || true
        case "${ans:-}" in
            y|Y) return 0 ;;
            *)   return 1 ;;
        esac
    fi
}

warn() { echo "WARNING: $*"; }
ok()   { echo "OK: $*"; }
skip() { echo "SKIP: $*"; }

# _register_mcp <name> <json_entry> -- ~/.claude.json의 mcpServers에 등록 (idempotent)
# jq 우선, 없으면 python3 폴백, 둘 다 없으면 수동 안내
_register_mcp() {
    local _name="$1"
    local _entry="$2"
    local _target="$HOME/.claude.json"

    if command -v jq &>/dev/null; then
        if [[ -f "$_target" ]] && jq -e --arg n "$_name" '.mcpServers[$n]' "$_target" &>/dev/null; then
            skip "$_name MCP ~/.claude.json에 이미 등록됨"
            return
        fi
        local _tmp; _tmp="$(mktemp)"
        if [[ -f "$_target" ]]; then
            if jq --arg n "$_name" --argjson e "$_entry" \
                '.mcpServers //= {} | .mcpServers[$n] = $e' \
                "$_target" > "$_tmp" && mv "$_tmp" "$_target"; then
                ok "$_name MCP ~/.claude.json에 등록됨"
            else
                rm -f "$_tmp"
                warn "$_name MCP 등록 실패 (jq 오류)"
            fi
        else
            if jq -n --arg n "$_name" --argjson e "$_entry" \
                '{"mcpServers": {($n): $e}}' > "$_target"; then
                ok "~/.claude.json 생성 + $_name MCP 등록됨"
            else
                warn "$_name MCP 등록 실패"
            fi
        fi
    elif command -v python3 &>/dev/null; then
        MCP_NAME="$_name" MCP_ENTRY="$_entry" MCP_TARGET="$_target" \
        python3 -c '
import json, os, sys
name = os.environ["MCP_NAME"]
entry = json.loads(os.environ["MCP_ENTRY"])
target = os.environ["MCP_TARGET"]
data = {}
if os.path.exists(target):
    with open(target) as f:
        data = json.load(f)
if data.get("mcpServers", {}).get(name):
    print("SKIP: " + name + " MCP already registered"); sys.exit(0)
data.setdefault("mcpServers", {})[name] = entry
with open(target, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
print("OK: " + name + " MCP registered in ~/.claude.json")
'
    else
        warn "$_name MCP 수동 등록 필요 (jq/python3 없음):"
        echo "  ~/.claude.json 의 mcpServers 키에 추가:"
        echo "  \"$_name\": $_entry"
    fi
}

# ---------------------------------------------------
# 2. 컴포넌트 멀티셀렉트
# ---------------------------------------------------
echo "=== 설치할 컴포넌트 선택 (기본: 전체) ==="

INSTALL_RTK=false
INSTALL_CODEGRAPH=false
INSTALL_GRAPHIFY=false
INSTALL_SLIDES=false
INSTALL_PLANNOTATOR=false

# 컴포넌트 라벨 (역할 설명 포함) -- gum choose 표시 / plain read 안내 / 선택 요약에서 공용
_OPT_RTK="rtk (출력 토큰 압축 프록시)"
_OPT_CODEGRAPH="codegraph (심볼 단위 코드 인텔리전스 MCP)"
_OPT_GRAPHIFY="graphify (코드 지식 그래프 네비게이션)"
_OPT_SLIDES="slides-grab (HTML -> 슬라이드 덱 생성 CLI)"
_OPT_PLANNOTATOR="plannotator (Plan Mode 브라우저 리뷰 UI 바이너리)"

if [[ "$GUM_OK" == "true" ]]; then
    # gum choose --no-limit: 선택 항목을 한 줄씩 stdout 출력
    _sel_file="$(mktemp)"
    gum choose --no-limit "$_OPT_RTK" "$_OPT_CODEGRAPH" "$_OPT_GRAPHIFY" "$_OPT_SLIDES" "$_OPT_PLANNOTATOR" > "$_sel_file" || true
    grep -qxF "$_OPT_RTK"         "$_sel_file" && INSTALL_RTK=true
    grep -qxF "$_OPT_CODEGRAPH"   "$_sel_file" && INSTALL_CODEGRAPH=true
    grep -qxF "$_OPT_GRAPHIFY"    "$_sel_file" && INSTALL_GRAPHIFY=true
    grep -qxF "$_OPT_SLIDES"      "$_sel_file" && INSTALL_SLIDES=true
    grep -qxF "$_OPT_PLANNOTATOR" "$_sel_file" && INSTALL_PLANNOTATOR=true
    rm -f "$_sel_file"
else
    echo "번호를 공백으로 구분해 입력 (기본값: 전체 선택):"
    echo "  1) $_OPT_RTK"
    echo "  2) $_OPT_CODEGRAPH"
    echo "  3) $_OPT_GRAPHIFY"
    echo "  4) $_OPT_SLIDES"
    echo "  5) $_OPT_PLANNOTATOR"
    read -rp "> [기본: 1 2 3 4 5] " _raw_sel || true
    if [[ -z "${_raw_sel:-}" ]]; then
        _raw_sel="1 2 3 4 5"
    fi
    for _n in $_raw_sel; do
        case "$_n" in
            1) INSTALL_RTK=true ;;
            2) INSTALL_CODEGRAPH=true ;;
            3) INSTALL_GRAPHIFY=true ;;
            4) INSTALL_SLIDES=true ;;
            5) INSTALL_PLANNOTATOR=true ;;
        esac
    done
fi

echo
echo "선택된 컴포넌트:"
[[ "$INSTALL_RTK"         == "true" ]] && echo "  * $_OPT_RTK"
[[ "$INSTALL_CODEGRAPH"   == "true" ]] && echo "  * $_OPT_CODEGRAPH"
[[ "$INSTALL_GRAPHIFY"    == "true" ]] && echo "  * $_OPT_GRAPHIFY"
[[ "$INSTALL_SLIDES"      == "true" ]] && echo "  * $_OPT_SLIDES"
[[ "$INSTALL_PLANNOTATOR" == "true" ]] && echo "  * $_OPT_PLANNOTATOR"
echo

# ---------------------------------------------------
# 3. 전제 확인
# ---------------------------------------------------
echo "=== 전제 확인 ==="

# node/npm: 컴포넌트 선택과 무관한 전제다.
# statusLine(claude-dashboard 플러그인)이 `node dist/index.js`로 직접 실행되므로,
# slides-grab을 고르지 않아도 node가 없으면 statusLine이 점등되지 않는다.
if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
    warn "node/npm이 없습니다. statusLine(claude-dashboard)이 node로 실행되며, slides-grab도 npm이 필요합니다:"
    if [[ "$PLATFORM" == "macOS" ]]; then
        echo "  brew install node  또는  nvm install --lts"
    else
        echo "  nvm install --lts  또는  sudo apt-get install -y nodejs npm"
    fi
else
    ok "node $(node --version), npm $(npm --version)"
fi

if [[ "$INSTALL_GRAPHIFY" == "true" ]]; then
    if ! command -v uv &>/dev/null; then
        echo "uv가 없습니다. 자동 설치를 시도합니다..."
        if curl -LsSf https://astral.sh/uv/install.sh | sh; then
            export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
            ok "uv 설치 완료"
        else
            warn "uv 자동 설치 실패. 수동: https://docs.astral.sh/uv/getting-started/installation/"
        fi
    else
        ok "uv $(uv --version)"
    fi
fi

if [[ "$INSTALL_RTK" == "true" ]] && [[ "$PLATFORM" == "macOS" ]]; then
    if ! command -v brew &>/dev/null; then
        warn "Homebrew 없음. https://brew.sh 에서 설치 후 재실행하세요."
    fi
fi

# jq: 이 저장소 전체의 하드 의존이다 (rtk 컴포넌트 선택 여부와 무관).
# 없으면 아래가 전부 조용히 죽는다:
#   - hooks/rtk-rewrite.sh          (Bash 명령 rtk 재작성)
#   - hooks/workflow-stage-inject.sh (Skill 호출 시 단계 지침 주입)
#   - settings.json 인라인 PreToolUse 훅 2종
#     (.py 편집 시 python-coding-style 주입 / docs/plans·docs/superpowers/specs의 .md 한국어 강제)
# _register_mcp / 플러그인 안내도 jq를 선호하므로 section 4 이전에 확보한다.
if command -v jq &>/dev/null; then
    ok "jq $(jq --version)"
else
    echo "jq가 없습니다. 자동 설치를 시도합니다 (훅 전체의 하드 의존)..."
    _jq_installed=false
    if [[ "$PLATFORM" == "macOS" ]]; then
        if command -v brew &>/dev/null && spin "jq 설치 중 (brew)..." brew install jq; then
            _jq_installed=true
        fi
    else
        if command -v apt-get &>/dev/null \
            && spin "jq 설치 중 (apt)..." bash -c 'sudo apt-get install -y jq'; then
            _jq_installed=true
        fi
        # apt 실패 시 release binary fallback
        if [[ "$_jq_installed" == "false" ]]; then
            _local_bin="$HOME/.local/bin"
            mkdir -p "$_local_bin"
            case "$(uname -m)" in
                x86_64)  _jq_arch="amd64" ;;
                aarch64) _jq_arch="arm64" ;;
                *)       _jq_arch="amd64" ;;
            esac
            _jq_url="https://github.com/jqlang/jq/releases/latest/download/jq-linux-${_jq_arch}"
            if curl -fsSL "$_jq_url" -o "$_local_bin/jq" 2>/dev/null && chmod +x "$_local_bin/jq"; then
                export PATH="$_local_bin:$PATH"
                command -v jq &>/dev/null && _jq_installed=true
            fi
        fi
    fi

    if [[ "$_jq_installed" == "true" ]]; then
        ok "jq 설치 완료 ($(jq --version))"
    else
        warn "jq 설치 실패 -- rtk 재작성·워크플로우 단계 주입·python-coding-style·계획 한국어 강제 훅이 모두 비활성화됩니다."
        if [[ "$PLATFORM" == "macOS" ]]; then
            echo "  수동: brew install jq"
        else
            echo "  수동: sudo apt-get install -y jq  또는  https://jqlang.github.io/jq/download/"
        fi
    fi
fi

# ugrep(ug) / bfs: rules/boundaries.md의 "Search / lookup"이 전제하는 검색 보조 도구.
# jq와 달리 소프트 의존이다 -- 없어도 훅은 그대로 돌고, grep/find로 폴백되며,
# settings.json의 codegraph 보완 안내 훅 정규식이 매칭되지 않을 뿐이다.
# 그래서 실패해도 DOCTOR_ISSUES에 넣지 않고 안내만 남긴다.
_missing_search_tools=()
command -v ugrep &>/dev/null || _missing_search_tools+=("ugrep")
command -v bfs   &>/dev/null || _missing_search_tools+=("bfs")

if [[ ${#_missing_search_tools[@]} -eq 0 ]]; then
    ok "ugrep $(ugrep --version 2>/dev/null | head -1 | awk '{print $2}'), bfs $(bfs --version 2>/dev/null | head -1 | awk '{print $2}')"
else
    echo "검색 보조 도구가 없습니다 (${_missing_search_tools[*]}). 설치를 시도합니다..."
    _search_installed=false
    if [[ "$PLATFORM" == "macOS" ]]; then
        if command -v brew &>/dev/null \
            && spin "ugrep·bfs 설치 중 (brew)..." brew install "${_missing_search_tools[@]}"; then
            _search_installed=true
        fi
    else
        if command -v apt-get &>/dev/null \
            && spin "ugrep·bfs 설치 중 (apt)..." \
                bash -c "sudo apt-get install -y ${_missing_search_tools[*]}"; then
            _search_installed=true
        fi
    fi

    if [[ "$_search_installed" == "true" ]]; then
        ok "ugrep·bfs 설치 완료"
    else
        warn "ugrep·bfs 설치 실패 -- 아카이브 검색(-z)·퍼지 매칭·빠른 breadth-first find를 쓸 수 없습니다 (grep/find로 폴백되므로 치명적이지는 않습니다)."
        if [[ "$PLATFORM" == "macOS" ]]; then
            echo "  수동: brew install ugrep bfs"
        else
            echo "  수동: sudo apt-get install -y ugrep bfs  또는  https://github.com/Genivia/ugrep · https://github.com/tavianator/bfs"
        fi
    fi
fi

echo

# ---------------------------------------------------
# 4. 툴별 idempotent 설치
# ---------------------------------------------------
echo "=== 툴 설치 ==="
FAILED_TOOLS=()

# ---- rtk ----
if [[ "$INSTALL_RTK" == "true" ]]; then
    if command -v rtk &>/dev/null; then
        skip "rtk 이미 설치됨"
    else
        echo "rtk 설치 중..."
        _rtk_installed=false
        if [[ "$PLATFORM" == "macOS" ]]; then
            if command -v brew &>/dev/null; then
                spin "rtk 설치 중 (brew tap)..." brew tap reachingforthejack/rtk 2>/dev/null || true
                if spin "rtk 설치 중 (brew install)..." brew install rtk 2>/dev/null; then
                    _rtk_installed=true
                fi
            fi
        else
            _local_bin="$HOME/.local/bin"
            mkdir -p "$_local_bin"
            case "$(uname -m)" in
                x86_64)  _rtk_bin="rtk-x86_64-unknown-linux-musl" ;;
                aarch64) _rtk_bin="rtk-aarch64-unknown-linux-musl" ;;
                *)       _rtk_bin="rtk-x86_64-unknown-linux-musl" ;;
            esac
            _rtk_url="https://github.com/reachingforthejack/rtk/releases/latest/download/${_rtk_bin}"
            if curl -fsSL "$_rtk_url" -o "$_local_bin/rtk" 2>/dev/null && chmod +x "$_local_bin/rtk"; then
                export PATH="$_local_bin:$PATH"
                _rtk_installed=true
            fi
        fi

        if [[ "$_rtk_installed" == "true" ]]; then
            ok "rtk 설치 완료"
            # 이름 충돌 검증
            if rtk gain &>/dev/null; then
                ok "rtk gain 통과 (이름 충돌 없음)"
            else
                warn "rtk gain 실패 -- 다른 rtk 패키지가 있을 수 있습니다. 확인: which rtk"
            fi
        else
            warn "rtk 설치 실패."
            FAILED_TOOLS+=("rtk")
            if [[ "$PLATFORM" == "macOS" ]]; then
                echo "  수동: brew tap reachingforthejack/rtk && brew install rtk"
            else
                echo "  수동: https://github.com/reachingforthejack/rtk/releases 에서 바이너리 다운로드"
            fi
        fi
    fi

    # RTK.md 생성 -- rtk 직후 (CLAUDE.md @RTK.md 의존, 순서 필수)
    if command -v rtk &>/dev/null; then
        echo "RTK.md 글로벌 초기화 중 (rtk init -g)..."
        if rtk init -g; then
            ok "RTK.md 생성 완료"
        else
            warn "rtk init -g 실패. 수동: rtk init -g"
            FAILED_TOOLS+=("rtk init -g")
        fi
    fi

    # rtk config: grep·find를 재작성 대상에서 제외한다.
    # 2.1.117 네이티브 빌드는 셸 스냅샷에서 grep·find를 임베디드 ugrep·bfs로 shadow하는데,
    # rtk가 이를 `rtk grep`으로 바꾸면 별도 프로세스에서 BSD grep이 돌아
    # --ignore-files(gitignore 인식)를 잃는다. 포맷이 아니라 결과가 달라지는 문제다.
    # (`rtk rg`는 ripgrep을 그대로 실행해 gitignore를 유지하므로 제외하지 않는다.)
    if command -v rtk &>/dev/null; then
        _rtk_cfg="$(rtk config 2>/dev/null | LC_ALL=C /usr/bin/grep -m1 '^Config:' | cut -d' ' -f2-)"
        [[ -n "${_rtk_cfg:-}" && ! -f "$_rtk_cfg" ]] && rtk config --create &>/dev/null || true

        if [[ -z "${_rtk_cfg:-}" || ! -f "$_rtk_cfg" ]]; then
            warn "rtk config 파일을 찾을 수 없어 grep·find 제외를 건너뜁니다. 수동: rtk config 로 경로 확인 후 [hooks] exclude_commands 편집"
        elif ! command -v python3 &>/dev/null; then
            warn "python3 없음 -- rtk exclude_commands 자동 설정 불가."
            echo "  수동: $_rtk_cfg 의 [hooks] 아래를 exclude_commands = [\"grep\", \"find\"] 로 편집"
        else
            _rtk_res="$(python3 - "$_rtk_cfg" <<'PY' 2>/dev/null || true
import re, sys

path = sys.argv[1]
src = open(path, encoding="utf-8").read()
hit = re.search(r"^[ \t]*exclude_commands[ \t]*=[ \t]*\[(.*?)\]", src, re.M | re.S)
if hit is None:
    print("MISSING")
    sys.exit(0)

have = set(re.findall(r"""["']([^"']+)["']""", hit.group(1)))
want = have | {"grep", "find"}
if want == have:
    print("SKIP")
    sys.exit(0)

items = ", ".join('"%s"' % name for name in sorted(want))
open(path, "w", encoding="utf-8").write(
    src[: hit.start()] + "exclude_commands = [%s]" % items + src[hit.end() :]
)
print("OK")
PY
)"
            case "${_rtk_res:-}" in
                OK)      ok "rtk config: grep·find를 재작성 제외에 추가 ($_rtk_cfg)" ;;
                SKIP)    skip "rtk config: grep·find 이미 제외됨" ;;
                MISSING) warn "rtk config에 [hooks] exclude_commands 항목이 없습니다. 수동 추가 필요: $_rtk_cfg" ;;
                *)       warn "rtk config 편집 실패. 수동: $_rtk_cfg 의 exclude_commands = [\"grep\", \"find\"]" ;;
            esac
        fi
    fi
fi

# ---- codegraph ----
if [[ "$INSTALL_CODEGRAPH" == "true" ]]; then
    if command -v codegraph &>/dev/null; then
        skip "codegraph 이미 설치됨"
    else
        echo "codegraph 설치 중..."
        if spin "codegraph 설치 중..." \
            bash -c 'curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh'; then
            ok "codegraph 설치 완료"
        else
            warn "codegraph 설치 실패."
            FAILED_TOOLS+=("codegraph")
            echo "  수동: curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh"
        fi
    fi
    # 바이너리가 있으면 MCP 등록 (설치 직후 or 이미 설치된 경우 모두 idempotent)
    if command -v codegraph &>/dev/null; then
        _register_mcp "codegraph" '{"type":"stdio","command":"codegraph","args":["serve","--mcp"]}'
    fi
fi

# ---- graphify ----
if [[ "$INSTALL_GRAPHIFY" == "true" ]]; then
    if command -v graphify &>/dev/null; then
        skip "graphify 이미 설치됨"
    else
        echo "graphify 설치 중..."
        if command -v uv &>/dev/null; then
            if spin "graphify 설치 중 (uv tool install)..." uv tool install graphifyy; then
                ok "graphify 설치 완료"
            else
                warn "graphify 설치 실패."
                FAILED_TOOLS+=("graphify")
                echo "  수동: uv tool install graphifyy"
            fi
        else
            warn "uv 없음 -- graphify 설치 불가."
            FAILED_TOOLS+=("graphify")
            echo "  수동: uv tool install graphifyy  (uv 설치 후)"
        fi
    fi
fi

# ---- slides-grab ----
if [[ "$INSTALL_SLIDES" == "true" ]]; then
    if command -v slides-grab &>/dev/null; then
        skip "slides-grab 이미 설치됨"
    else
        echo "slides-grab 설치 중..."
        if command -v npm &>/dev/null; then
            if spin "slides-grab 설치 중 (npm)..." npm install -g slides-grab; then
                ok "slides-grab 설치 완료"
            else
                warn "slides-grab 설치 실패."
                FAILED_TOOLS+=("slides-grab")
                echo "  수동: npm install -g slides-grab"
            fi
        else
            warn "npm 없음 -- slides-grab 설치 불가."
            FAILED_TOOLS+=("slides-grab")
            echo "  수동: npm install -g slides-grab  (node/npm 설치 후)"
        fi
    fi
fi

# ---- plannotator (Plan Mode 브라우저 리뷰 UI 바이너리) ----
# 주의: 이 바이너리는 plannotator@plannotator 플러그인의 prerequisite다.
# 플러그인 훅(PermissionRequest:ExitPlanMode)이 PATH의 `plannotator` 커맨드를 호출하므로,
# settings.json으로 플러그인이 자동 설치돼도 이 바이너리가 없으면 Plan 리뷰 UI가 동작하지 않는다.
if [[ "$INSTALL_PLANNOTATOR" == "true" ]]; then
    if command -v plannotator &>/dev/null; then
        skip "plannotator 이미 설치됨"
    else
        echo "plannotator 설치 중..."
        if spin "plannotator 설치 중..." \
            bash -c 'curl -fsSL https://plannotator.ai/install.sh | bash'; then
            export PATH="$HOME/.local/bin:$PATH"
            if command -v plannotator &>/dev/null; then
                ok "plannotator 설치 완료"
            else
                warn "plannotator 설치는 됐으나 PATH에서 찾을 수 없습니다 -- ~/.local/bin을 PATH에 추가하세요."
            fi
        else
            warn "plannotator 설치 실패."
            FAILED_TOOLS+=("plannotator")
            echo "  수동: curl -fsSL https://plannotator.ai/install.sh | bash"
        fi
    fi
fi

echo

# ---------------------------------------------------
# 5. 플러그인 안내
# ---------------------------------------------------
echo "=== 플러그인 안내 ==="
# enabledPlugins는 배열이 아니라 {"플러그인@마켓플레이스": true|false} 객체다.
# `.[]`로 순회하면 이름이 아니라 true/false만 찍히므로 to_entries로 켜진 키만 뽑는다.
if [[ -f "$SETTINGS_FILE" ]]; then
    if command -v jq &>/dev/null; then
        echo "settings.json enabledPlugins (활성):"
        jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value) | "  * " + .key' \
            "$SETTINGS_FILE" 2>/dev/null || true
        _disabled="$(jq -r '(.enabledPlugins // {}) | to_entries[] | select(.value | not) | "  - " + .key' \
            "$SETTINGS_FILE" 2>/dev/null || true)"
        if [[ -n "$_disabled" ]]; then
            echo "비활성 (필요하면 /plugin으로 되살림):"
            echo "$_disabled"
        fi
    else
        echo "settings.json enabledPlugins (jq 없음 -- 원문 일부만 표시):"
        LC_ALL=C grep -A20 '"enabledPlugins"' "$SETTINGS_FILE" 2>/dev/null | head -20 || true
    fi
fi
echo "-> Claude Code 재시작 시 위 플러그인이 자동 설치됩니다."
echo

# ---------------------------------------------------
# 6. 메모리 seed 동기화
# ---------------------------------------------------
_sync_script="$SCRIPT_DIR/sync-memory-templates.sh"
if [[ -f "$_sync_script" ]]; then
    if confirm "메모리 seed를 동기화할까요? (memory-templates/ -> ~/.claude/projects/.../memory/)"; then
        echo "메모리 seed 동기화 중..."
        if bash "$_sync_script"; then
            ok "메모리 seed 동기화 완료"
        else
            warn "메모리 seed 동기화 실패. 수동: bash $SCRIPT_DIR/sync-memory-templates.sh"
        fi
    else
        skip "메모리 seed 동기화"
    fi
else
    warn "$_sync_script 를 찾을 수 없습니다."
fi
echo

# ---------------------------------------------------
# 7. settings.json 로컬 블록 clean/smudge 필터 등록
# ---------------------------------------------------
# git은 파일 내부 블록 단위 추적 제외를 지원하지 않는다. 그런데 grrr 알림 훅은
# 이 머신에만 있는 CLI에 의존하면서도 모든 프로젝트에서 울려야 해서
# ~/.claude/settings.json 안에 물리적으로 있어야 한다 -- Claude Code의
# localSettings는 언제나 <프로젝트 루트>/.claude/settings.local.json 이고
# user 스코프에는 local 오버레이가 아예 없기 때문이다.
#
# 그래서 파일을 나누는 대신 커밋 경로에서만 걷어낸다. 예전의 skip-worktree는
# 파일 전체를 숨겨서 settings.json을 계속 커밋하는 지금 워크플로우와 충돌하므로
# 해제하고 필터로 대체한다. 필터 설정은 .git/config에 살아 clone마다 사라지므로
# 여기서 idempotent하게 다시 건다.
echo "=== settings.json 로컬 블록 필터 등록 ==="
cd "$REPO_ROOT"
_filter_script="scripts/git-filter-settings.sh"
if [[ ! -x "$REPO_ROOT/$_filter_script" ]]; then
    warn "$_filter_script 없음(또는 실행권한 없음) -- 필터 등록을 건너뜁니다."
    FAILED_TOOLS+=("git filter: $_filter_script")
elif ! command -v jq &>/dev/null; then
    warn "jq 없음 -- clean/smudge 필터가 동작할 수 없으므로 등록하지 않습니다."
    FAILED_TOOLS+=("git filter: jq 없음")
else
    if git ls-files -v settings.json 2>/dev/null | /usr/bin/grep -q '^S'; then
        git update-index --no-skip-worktree settings.json
        ok "이전 skip-worktree 해제됨 (필터 방식으로 대체)"
    fi

    # required=true: 등록은 됐는데 필터 스크립트가 깨진 경우(jq 없음, 파일 삭제)
    # 조용히 원본을 통과시키지 않고 실패시킨다. 이 설정 자체가 .git/config에 살아
    # clone을 따라가지 않으므로, 미등록 clone은 보호하지 못한다 -- 그쪽의 안전장치는
    # 이 설치기를 다시 도는 것뿐이다.
    git config filter.claude-local.clean  "$_filter_script clean"
    git config filter.claude-local.smudge "$_filter_script smudge"
    git config filter.claude-local.required true
    ok "filter.claude-local 등록됨 (.gitattributes의 /settings.json 규칙이 물림)"

    if [[ -f "$REPO_ROOT/local-hooks.json" ]]; then
        ok "local-hooks.json 존재 (smudge 복원 원본)"
    else
        warn "local-hooks.json 없음 -- 이 머신에는 복원할 로컬 훅이 없습니다."
        echo "  grrr 알림 훅을 쓰려면 아래 형태로 직접 만드세요 (.gitignore 대상):"
        echo '    {"hooks":{"Stop":[...],"Notification":[...],"UserPromptSubmit":[...]}}'
    fi
fi
echo

# ---------------------------------------------------
# 8. 훅·의존성 점검 (doctor)
# ---------------------------------------------------
# 툴을 설치했다고 훅이 도는 건 아니다. 훅은 실패해도 조용하므로
# (Claude Code가 hook stderr를 세션 로그로만 남김) 여기서 명시적으로 확인한다.
echo "=== 훅·의존성 점검 ==="
DOCTOR_ISSUES=()

_doctor_fail() {
    warn "$1"
    DOCTOR_ISSUES+=("$1")
}

# 8-1. settings.json이 실제로 호출하는 커맨드가 해석되는지
# 커맨드 목록을 하드코딩하지 않고 settings.json에서 추출한다 --
# 그래야 이 저장소에 없는 머신 로컬 훅(알림 훅 등)까지 같은 방식으로 걸린다.
if [[ ! -f "$SETTINGS_FILE" ]]; then
    _doctor_fail "settings.json을 찾을 수 없습니다: $SETTINGS_FILE"
elif ! command -v jq &>/dev/null; then
    _doctor_fail "jq 없음 -- 훅 커맨드 점검 불가. jq 자체가 훅의 하드 의존이므로, 이 상태에서는 rtk 재작성·워크플로우 단계 주입·python-coding-style·계획 한국어 강제 훅이 전부 동작하지 않습니다."
else
    _hook_cmds="$(jq -r '
        [ (.hooks // {}) | .. | objects | select(.type? == "command") | .command? // empty ]
        + [ (.statusLine // {}) | select(.type? == "command") | .command? // empty ]
        | .[]
    ' "$SETTINGS_FILE" 2>/dev/null || true)"

    _seen=" "
    while IFS= read -r _cmdline; do
        [[ -z "$_cmdline" ]] && continue
        read -r _bin _rest <<< "$_cmdline"

        # `bash <script>` 형태는 인터프리터가 아니라 스크립트 자체가 점검 대상이다.
        # 단 이 경우 실행권한은 불필요하므로(인터프리터가 읽기만 한다) 존재만 본다.
        _via_interp=false
        case "$_bin" in
            bash|sh|zsh)
                read -r _bin2 _ <<< "${_rest:-}"
                if [[ -n "${_bin2:-}" ]]; then
                    _bin="$_bin2"
                    _via_interp=true
                fi
                ;;
        esac

        # settings.json은 $HOME 문자열을 그대로 담고 Claude Code가 확장한다.
        _bin="${_bin//\$HOME/$HOME}"
        _bin="${_bin/#\~/$HOME}"

        # 셸 빌트인만 쓰는 인라인 훅은 점검 대상이 아니다.
        case "$_bin" in
            echo|printf|true|:|"") continue ;;
        esac

        case "$_seen" in *" $_bin "*) continue ;; esac
        _seen="$_seen$_bin "

        if [[ "$_bin" == */* ]]; then
            if [[ ! -f "$_bin" ]]; then
                _doctor_fail "훅 스크립트 없음: $_bin"
            elif [[ "$_via_interp" == "true" || -x "$_bin" ]]; then
                ok "훅 스크립트 $_bin 사용 가능"
            else
                # 인터프리터 없이 직접 실행되는 훅만 실행권한이 필요하다.
                _doctor_fail "훅 스크립트 실행권한 없음: $_bin  (chmod +x 필요)"
            fi
        elif command -v "$_bin" &>/dev/null; then
            ok "훅 커맨드 $_bin 사용 가능"
        else
            _doctor_fail "훅 커맨드를 PATH에서 찾을 수 없음: $_bin  (해당 훅이 동작하지 않습니다)"
        fi
    done <<< "$_hook_cmds"
fi

# 8-2. 추적 스킬 3종
# 별도 설치 경로가 없다 -- clone에 포함되어 그 자리가 곧 로드 위치다.
# 부분 clone이나 .gitignore opt-in 누락으로 빠지면 CLAUDE.md 스킬 표가
# 존재하지 않는 스킬을 가리키게 되므로 존재 여부만 확인한다.
for _skill in fastapi-project-structure python-architecture python-coding-style; do
    if [[ -f "$REPO_ROOT/skills/$_skill/SKILL.md" ]]; then
        ok "손-작성 스킬 $_skill 존재"
    else
        _doctor_fail "손-작성 스킬 누락: skills/$_skill/SKILL.md  (git clone 상태 확인 필요)"
    fi
done

# 8-3. RTK.md -- CLAUDE.md가 @RTK.md로 import한다 (없으면 import가 깨짐)
if [[ -f "$HOME/.claude/RTK.md" ]]; then
    ok "RTK.md 존재"
else
    _doctor_fail "RTK.md 없음 -- CLAUDE.md의 @RTK.md import가 깨집니다. 해결: rtk init -g"
fi

echo

# ---------------------------------------------------
# 9. 요약 + 수동 단계 출력
# ---------------------------------------------------
echo "======================================"
echo "         설치 완료 요약"
echo "======================================"
echo

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    warn "설치 실패 항목:"
    for _t in "${FAILED_TOOLS[@]}"; do
        echo "  * $_t"
    done
    echo
fi

if [[ ${#DOCTOR_ISSUES[@]} -gt 0 ]]; then
    warn "훅·의존성 점검 미해결 항목:"
    for _t in "${DOCTOR_ISSUES[@]}"; do
        echo "  * $_t"
    done
    echo
else
    ok "훅·의존성 점검 전부 통과"
    echo
fi

echo "수동으로 완료해야 하는 단계:"
echo
echo "  1. Claude Code 재시작"
echo "     -> 플러그인 자동 설치 (superpowers, security-guidance 등)"
echo
echo "  2. 나머지 MCP 서버 수동 설정"
echo "     -> computer-use, sequential-thinking 등 (codegraph는 자동 등록됨)"
echo "     -> 설정: ~/.claude.json  (mcpServers 키)"
echo
echo "  3. clone 후 매번: settings.json 로컬 블록 필터 재확인 (필수)"
echo "     -> git config --get filter.claude-local.clean   (비어 있으면 이 설치기 재실행)"
echo "     -> 미등록 상태에서는 git이 경고 없이 로컬 훅을 그대로 커밋합니다."
echo "     -> local-hooks.json은 .gitignore 대상이라 clone에 따라오지 않습니다."
echo "        이 머신의 grrr 알림 훅을 옮기려면 파일째 직접 복사하세요."
echo

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    echo "  4. 실패 툴 수동 설치 (위 목록 참조)"
    echo
fi

echo "설치기 종료."
