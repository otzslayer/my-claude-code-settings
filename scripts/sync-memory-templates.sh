#!/usr/bin/env bash
# sync-memory-templates.sh
#
# memory-templates/ 의 파일을 ~/.claude/projects/<host-slug>/memory/ 로 동기화.
# - host-slug 자동 검출 (모호하면 첫 인자 필요)
# - 템플릿 본문: 동일하면 skip, 다르면 unified diff 보여주고 [y/N/s] prompt
# - MEMORY-index.md: 각 라인을 MEMORY.md에 idempotent append

set -euo pipefail

# --- 경로 결정 ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$REPO_ROOT/memory-templates"
PROJECTS_ROOT="$HOME/.claude/projects"
INDEX_FILE="$TEMPLATES_DIR/MEMORY-index.md"

if [[ ! -d "$TEMPLATES_DIR" ]]; then
    echo "ERROR: $TEMPLATES_DIR 가 존재하지 않습니다." >&2
    exit 1
fi
if [[ ! -d "$PROJECTS_ROOT" ]]; then
    echo "ERROR: $PROJECTS_ROOT 가 존재하지 않습니다. Claude Code가 설치·실행된 적이 있는지 확인하세요." >&2
    exit 1
fi

# --- host-slug 검출 ---
shopt -s nullglob
slug_dirs=("$PROJECTS_ROOT"/*/)
shopt -u nullglob

if [[ ${#slug_dirs[@]} -eq 0 ]]; then
    echo "ERROR: $PROJECTS_ROOT 아래에 host-slug 디렉토리가 없습니다." >&2
    exit 1
fi

# Claude Code의 host-slug 인코딩: path의 '/' 와 '.' 를 '-' 로 치환.
# 예: /home/jay/.claude → -home-jay--claude
encode_slug() {
    local p="$1"
    p="${p//\//-}"
    p="${p//./-}"
    echo "$p"
}

target_slug_dir=""

if [[ $# -ge 1 ]]; then
    # 1순위: 사용자 인자
    explicit="$1"
    target_slug_dir="$PROJECTS_ROOT/$explicit"
    if [[ ! -d "$target_slug_dir" ]]; then
        echo "ERROR: 지정한 slug '$explicit' 디렉토리가 없습니다." >&2
        echo "사용 가능한 slug:" >&2
        for s in "${slug_dirs[@]}"; do echo "  $(basename "${s%/}")" >&2; done
        exit 1
    fi
else
    # 2순위: $HOME/.claude 인코딩 slug (= 글로벌 메모리)
    global_slug="$(encode_slug "$HOME/.claude")"
    if [[ -d "$PROJECTS_ROOT/$global_slug" ]]; then
        target_slug_dir="$PROJECTS_ROOT/$global_slug"
        echo "Detected global memory slug: $global_slug"
    elif [[ ${#slug_dirs[@]} -eq 1 ]]; then
        # 3순위: 디렉토리가 1개뿐이면 그것
        target_slug_dir="${slug_dirs[0]%/}"
    else
        # 그 외: MEMORY.md가 있는 후보만 추려 안내
        echo "ERROR: 글로벌 메모리 slug($global_slug)이 없고 디렉토리가 여러 개입니다." >&2
        echo "MEMORY.md를 가진 후보:" >&2
        for s in "${slug_dirs[@]}"; do
            slug_name="$(basename "${s%/}")"
            if [[ -f "${s%/}/memory/MEMORY.md" ]]; then
                echo "  $slug_name" >&2
            fi
        done
        echo "인자로 지정하세요. 예: bash scripts/sync-memory-templates.sh $global_slug" >&2
        exit 1
    fi
fi

MEMORY_DIR="$target_slug_dir/memory"
mkdir -p "$MEMORY_DIR"

echo "Target slug : $(basename "$target_slug_dir")"
echo "Memory dir  : $MEMORY_DIR"
echo

# auto memory 시스템이 디스크 파일에 자동 부여하는 host-local 메타·서식 차이를
# 흡수해 의미상 동일한지 판정. 본문 차이가 있을 때만 diff/prompt를 띄운다.
#  - originSessionId 줄 제거 (호스트별)
#  - node_type: memory 줄 제거 (시스템 자동 부여)
#  - description의 큰따옴표 양 끝 제거 (YAML 의미 동일)
#  - trailing whitespace 제거
normalize_memory_yaml() {
    # glibc sed의 UTF-8 locale에서 한국어 등 멀티바이트가 든 줄의 정규식 매칭이
    # 불안정하므로 byte 모드(LC_ALL=C) 강제. 한글 byte sequence는 보존됨.
    LC_ALL=C sed -E \
        -e '/^[[:space:]]*originSessionId:/d' \
        -e '/^[[:space:]]*node_type:[[:space:]]*memory[[:space:]]*$/d' \
        -e 's/^([[:space:]]*description:[[:space:]]*)"(.*)"[[:space:]]*$/\1\2/' \
        -e 's/[[:space:]]+$//' \
        "$1"
}

# --- 1) 템플릿 본문 동기화 ---
copied=0
skipped=0
unchanged=0
overwritten=0

for template in "$TEMPLATES_DIR"/*.md; do
    [[ -f "$template" ]] || continue
    filename="$(basename "$template")"
    # 인덱스·README는 본문 동기화 대상에서 제외
    case "$filename" in
        MEMORY-index.md|README.md) continue ;;
    esac

    target="$MEMORY_DIR/$filename"

    if [[ ! -f "$target" ]]; then
        cp "$template" "$target"
        echo "[+] $filename  (new)"
        copied=$((copied + 1))
        continue
    fi

    if cmp -s "$template" "$target"; then
        echo "[=] $filename  (unchanged)"
        unchanged=$((unchanged + 1))
        continue
    fi

    # host-local 노이즈 정규화 후 비교
    if diff -q <(normalize_memory_yaml "$template") <(normalize_memory_yaml "$target") > /dev/null 2>&1; then
        echo "[~] $filename  (host-local metadata only; equivalent)"
        unchanged=$((unchanged + 1))
        continue
    fi

    echo "[≠] $filename  (differs)"
    diff -u "$target" "$template" || true
    ans=""
    read -rp "    Overwrite ${filename}? [y/N/s(kip)] " ans || true
    case "${ans:-}" in
        y|Y)
            cp "$template" "$target"
            echo "    → overwritten"
            overwritten=$((overwritten + 1))
            ;;
        s|S|n|N|"")
            echo "    → skipped"
            skipped=$((skipped + 1))
            ;;
        *)
            echo "    → unknown answer, skipped"
            skipped=$((skipped + 1))
            ;;
    esac
done

# --- 2) MEMORY.md 인덱스 idempotent append ---
MEMORY_MD="$MEMORY_DIR/MEMORY.md"
if [[ ! -f "$MEMORY_MD" ]]; then
    printf '# Memory Index\n\n' > "$MEMORY_MD"
    echo "[+] MEMORY.md  (created)"
fi

index_added=0
index_present=0
if [[ -f "$INDEX_FILE" ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        # 빈 줄/주석 skip
        [[ -z "${line// /}" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if grep -qxF -- "$line" "$MEMORY_MD"; then
            index_present=$((index_present + 1))
        else
            # 파일 끝에 개행이 없으면 추가
            if [[ -s "$MEMORY_MD" ]] && [[ "$(tail -c1 "$MEMORY_MD" | xxd -p)" != "0a" ]]; then
                printf '\n' >> "$MEMORY_MD"
            fi
            printf '%s\n' "$line" >> "$MEMORY_MD"
            echo "[+] MEMORY.md ← $line"
            index_added=$((index_added + 1))
        fi
    done < "$INDEX_FILE"
fi

# --- 요약 ---
echo
echo "Summary:"
echo "  templates:  +${copied} new, ${unchanged} unchanged, ${overwritten} overwritten, ${skipped} skipped"
echo "  index:      +${index_added} appended, ${index_present} already present"
