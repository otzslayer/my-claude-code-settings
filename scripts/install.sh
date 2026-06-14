#!/usr/bin/env bash
# install.sh -- ~/.claude hybrid-workflow 의존 툴 인터랙티브 설치기
#
# 지원: macOS (brew) / WSL2 (apt/release binary)
# TUI:  gum (없으면 plain read 폴백)
# 순서: 플랫폼 감지 -> gum bootstrap -> 컴포넌트 선택 -> 전제 확인 ->
#        툴 설치 -> RTK.md 생성 -> 메모리 seed -> skip-worktree -> 요약

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

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

# ---------------------------------------------------
# 2. 컴포넌트 멀티셀렉트
# ---------------------------------------------------
echo "=== 설치할 컴포넌트 선택 (기본: 전체) ==="

INSTALL_RTK=false
INSTALL_CODEGRAPH=false
INSTALL_GRAPHIFY=false
INSTALL_SLIDES=false

if [[ "$GUM_OK" == "true" ]]; then
    # gum choose --no-limit: 선택 항목을 한 줄씩 stdout 출력
    _sel_file="$(mktemp)"
    gum choose --no-limit "rtk" "codegraph" "graphify" "slides-grab" > "$_sel_file" || true
    grep -qx "rtk"         "$_sel_file" && INSTALL_RTK=true
    grep -qx "codegraph"   "$_sel_file" && INSTALL_CODEGRAPH=true
    grep -qx "graphify"    "$_sel_file" && INSTALL_GRAPHIFY=true
    grep -qx "slides-grab" "$_sel_file" && INSTALL_SLIDES=true
    rm -f "$_sel_file"
else
    echo "번호를 공백으로 구분해 입력 (기본값: 전체 선택):"
    echo "  1) rtk"
    echo "  2) codegraph"
    echo "  3) graphify"
    echo "  4) slides-grab"
    read -rp "> [기본: 1 2 3 4] " _raw_sel || true
    if [[ -z "${_raw_sel:-}" ]]; then
        _raw_sel="1 2 3 4"
    fi
    for _n in $_raw_sel; do
        case "$_n" in
            1) INSTALL_RTK=true ;;
            2) INSTALL_CODEGRAPH=true ;;
            3) INSTALL_GRAPHIFY=true ;;
            4) INSTALL_SLIDES=true ;;
        esac
    done
fi

echo
echo "선택된 컴포넌트:"
[[ "$INSTALL_RTK"        == "true" ]] && echo "  * rtk"
[[ "$INSTALL_CODEGRAPH"  == "true" ]] && echo "  * codegraph"
[[ "$INSTALL_GRAPHIFY"   == "true" ]] && echo "  * graphify"
[[ "$INSTALL_SLIDES"     == "true" ]] && echo "  * slides-grab"
echo

# ---------------------------------------------------
# 3. 전제 확인
# ---------------------------------------------------
echo "=== 전제 확인 ==="

if [[ "$INSTALL_SLIDES" == "true" ]]; then
    if ! command -v node &>/dev/null || ! command -v npm &>/dev/null; then
        warn "node/npm이 없습니다. slides-grab 설치를 위해 수동 설치 필요:"
        if [[ "$PLATFORM" == "macOS" ]]; then
            echo "  brew install node  또는  nvm install --lts"
        else
            echo "  nvm install --lts  또는  sudo apt-get install -y nodejs npm"
        fi
    else
        ok "node $(node --version), npm $(npm --version)"
    fi
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

echo

# ---------------------------------------------------
# 5. 플러그인 안내
# ---------------------------------------------------
echo "=== 플러그인 안내 ==="
_settings="$REPO_ROOT/settings.json"
if [[ -f "$_settings" ]]; then
    if command -v jq &>/dev/null; then
        echo "settings.json enabledPlugins:"
        jq -r '.enabledPlugins // [] | .[]' "$_settings" 2>/dev/null | LC_ALL=C sed 's/^/  * /' || true
    else
        echo "settings.json enabledPlugins (jq 없음 -- 일부만 표시):"
        LC_ALL=C grep -A20 '"enabledPlugins"' "$_settings" 2>/dev/null | head -15 || true
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
# 7. skip-worktree (permissions 재유입 가드)
# ---------------------------------------------------
echo "=== skip-worktree 적용 ==="
cd "$REPO_ROOT"
if git ls-files --error-unmatch settings.json &>/dev/null 2>&1; then
    git update-index --skip-worktree settings.json
    ok "settings.json skip-worktree 적용됨"
    echo "  확인: git ls-files -v settings.json  (S 표시 = 정상)"
    echo "  해제: git update-index --no-skip-worktree settings.json"
else
    warn "settings.json이 git 추적 대상이 아닙니다. skip-worktree 스킵."
fi
echo

# ---------------------------------------------------
# 8. 요약 + 수동 단계 출력
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

echo "수동으로 완료해야 하는 단계:"
echo
echo "  1. Claude Code 재시작"
echo "     -> 플러그인 자동 설치 (compound-engineering, superpowers 등)"
echo
echo "  2. MCP 서버 수동 설정"
echo "     -> codegraph, computer-use, sequential-thinking 등"
echo "     -> 설정: ~/.claude/settings.json  (mcp 섹션)"
echo
echo "  3. clone 후 매번: skip-worktree 재확인"
echo "     -> git ls-files -v settings.json"
echo "     -> 'S' 없으면: git update-index --skip-worktree settings.json"
echo

if [[ ${#FAILED_TOOLS[@]} -gt 0 ]]; then
    echo "  4. 실패 툴 수동 설치 (위 목록 참조)"
    echo
fi

echo "설치기 종료."
