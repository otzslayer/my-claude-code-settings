"""upstream taxonomy 변경을 감지해 사람이 검토할 리포트를 출력한다.

`im-not-ai`의 ai-tell-taxonomy.md를 pinned commit과 HEAD 두 시점에서
fetch한 뒤 ID·severity를 diff하고, translationese-patterns.md의 분류
대장(ledger)과 대조한다.
자동 흡수·자동 파일 수정은 하지 않는다 — 수동 follow-up용 경량 스크립트다.

사용: `uv run python resync_translationese.py`  (gh CLI + 네트워크 필요)
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path

REPO = "epoko77-ai/im-not-ai"
TAXONOMY_PATH = ".claude/skills/humanize-korean/references/ai-tell-taxonomy.md"
RAW_URL = "https://raw.githubusercontent.com/{repo}/{ref}/{path}"
PATTERNS_FILE = Path(__file__).with_name("translationese-patterns.md")
SANITY_FLOOR = 30

_ID_RE = re.compile(r"^### (?P<id>[A-J]-\d+)\.")
_SEV_RE = re.compile(r"\[(?P<sev>S\d)[^\]]*\]")
_AJ_ID_RE = re.compile(r"^[A-J]-\d+$")
_LEDGER_KEYS = ("absorbed", "already_covered", "excluded", "deferred")
_SEV_RANK: dict[str | None, int] = {"S1": 3, "S2": 2, "S3": 1, None: 0}


@dataclass
class Ledger:
    """translationese-patterns.md YAML 헤더의 분류 대장."""

    pinned_commit: str
    absorbed: list[str] = field(default_factory=list)
    already_covered: list[str] = field(default_factory=list)
    excluded: list[str] = field(default_factory=list)
    deferred: list[str] = field(default_factory=list)

    def aj_union(self) -> set[str]:
        """네 목록 합집합 중 A-J ID만 (PE15 등 taxonomy-exempt 제외)."""
        ids: set[str] = set()
        for key in _LEDGER_KEYS:
            ids.update(t for t in getattr(self, key) if _AJ_ID_RE.match(t))
        return ids


# ── 순수 파싱 함수 ───────────────────────────────────────────────────


def parse_ids(text: str) -> dict[str, str | None]:
    """taxonomy 본문에서 {ID: severity|None} 추출 (ID-first, severity-second).

    severity 부재(예: A-17 HOLD)나 `[S2 · estimated]` 변종을 모두 포착한다.
    카테고리 헤더(`## A. …`)와 비패턴 `###` 라인은 ID regex가 자연히 배제한다.
    """
    ids: dict[str, str | None] = {}
    for line in text.splitlines():
        m = _ID_RE.match(line)
        if not m:
            continue
        sev = _SEV_RE.search(line)
        ids[m.group("id")] = sev.group("sev") if sev else None
    return ids


def parse_ledger(md_text: str) -> Ledger:
    """YAML `---` 헤더에서 4목록 + pinned_commit을 추출한다."""
    header = _yaml_header(md_text)
    lists: dict[str, list[str]] = {}
    pinned = ""
    for raw in header.splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or ":" not in line:
            continue
        key, _, value = line.partition(":")
        key = key.strip()
        if key == "pinned_commit":
            pinned = value.strip().strip('"')
        elif key in _LEDGER_KEYS:
            lists[key] = _parse_list(value)
    return Ledger(pinned_commit=pinned, **lists)


def _yaml_header(md_text: str) -> str:
    parts = md_text.split("---", 2)
    if len(parts) < 3 or parts[0].strip():
        raise ValueError("YAML 헤더(--- 블록)를 찾지 못했습니다.")
    return parts[1]


def _parse_list(value: str) -> list[str]:
    inner = value.strip().strip("[]")
    items = (tok.strip().strip('"').strip("'") for tok in inner.split(","))
    return [tok for tok in items if tok]


# ── 리포트 생성 (순수) ───────────────────────────────────────────────


def _rank(sev: str | None) -> int:
    return _SEV_RANK.get(sev, 0)


def _s(sev: str | None) -> str:
    return sev or "없음"


def _id_key(id_: str) -> tuple[str, int]:
    letter, _, num = id_.partition("-")
    return (letter, int(num) if num.isdigit() else 0)


def _block(title: str, items: list[str]) -> list[str]:
    return [title, *(items or ["  없음"]), ""]


def build_report(
    ledger: Ledger,
    ids_pinned: Mapping[str, str | None],
    ids_head: Mapping[str, str | None],
    head_sha: str,
    head_date: str,
) -> str:
    """KTD-2 4종 리포트(신규 / severity 변경 / deferred 상승 / 버전)."""
    union = ledger.aj_union()
    new_ids = sorted(set(ids_head) - union, key=_id_key)
    changed = [
        i
        for i in sorted(union, key=_id_key)
        if i in ids_pinned and i in ids_head and ids_pinned[i] != ids_head[i]
    ]
    risen = [
        i
        for i in sorted(ledger.deferred, key=_id_key)
        if _rank(ids_head.get(i)) > _rank(ids_pinned.get(i))
    ]
    out = [
        "번역투 패턴 upstream resync 리포트",
        f"출처: {REPO}@{head_sha[:12]} ({head_date})",
        f"pinned: {ledger.pinned_commit}",
        "",
    ]
    out += _block(
        "[1] 신규 ID (분류 대장에 없음 — 검토 필요)",
        [f"  - {i} [{_s(ids_head[i])}]" for i in new_ids],
    )
    out += _block(
        "[2] severity 변경 (재평가)",
        [f"  - {i}: {_s(ids_pinned[i])} → {_s(ids_head[i])}" for i in changed],
    )
    out += _block(
        "[3] deferred 심각도 상승 (보류 해제 검토)",
        [
            f"  - {i}: {_s(ids_pinned.get(i))} → {_s(ids_head.get(i))}"
            for i in risen
        ],
    )
    out += _version_block(ledger, head_sha)
    return "\n".join(out)


def _version_block(ledger: Ledger, head_sha: str) -> list[str]:
    # pinned_commit은 short SHA(12자)이므로 full HEAD SHA의 prefix로 비교한다.
    pinned = ledger.pinned_commit
    if pinned and head_sha.startswith(pinned):
        return ["[4] 버전 변경", "  pinned == HEAD — 변경 없음"]
    return [
        "[4] 버전 변경",
        f"  pinned({pinned}) ≠ HEAD({head_sha[:12]}) — "
        "버전 관리 섹션 변경 가능. diff 권장.",
    ]


# ── I/O (네트워크·subprocess) ────────────────────────────────────────


def fetch_taxonomy(ref: str) -> str:
    """raw.githubusercontent.com에서 taxonomy 본문을 fetch한다."""
    url = RAW_URL.format(repo=REPO, ref=ref, path=TAXONOMY_PATH)
    if not url.startswith("https://"):
        raise ValueError("https URL만 허용됩니다.")
    with urllib.request.urlopen(url, timeout=30) as resp:  # noqa: S310
        return resp.read().decode("utf-8")


def fetch_head_commit() -> tuple[str, str]:
    """gh api로 main HEAD의 (sha, committer date)를 조회한다."""
    result = subprocess.run(  # noqa: S603
        ["gh", "api", f"repos/{REPO}/commits/main"],  # noqa: S607
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    return data["sha"], data["commit"]["committer"]["date"]


def main() -> int:
    try:
        ledger = parse_ledger(PATTERNS_FILE.read_text(encoding="utf-8"))
    except (OSError, ValueError) as exc:
        print(f"[에러] ledger 로드 실패: {exc}", file=sys.stderr)
        return 1
    try:
        head_sha, head_date = fetch_head_commit()
    except FileNotFoundError:
        print(
            "[에러] gh CLI를 찾을 수 없습니다. "
            "GitHub CLI 설치·인증이 필요합니다.",
            file=sys.stderr,
        )
        return 1
    except subprocess.CalledProcessError as exc:
        print(
            "[에러] gh api 호출 실패(인증·rate-limit 확인): "
            f"{exc.stderr.strip()}",
            file=sys.stderr,
        )
        return 1
    except (json.JSONDecodeError, KeyError) as exc:
        print(
            f"[에러] gh api 응답 형식이 예상과 다릅니다: {exc}",
            file=sys.stderr,
        )
        return 1
    try:
        text_pinned = fetch_taxonomy(ledger.pinned_commit)
        text_head = fetch_taxonomy(head_sha)
    except (urllib.error.URLError, OSError) as exc:
        print(
            f"[에러] taxonomy fetch 실패(네트워크 확인): {exc}",
            file=sys.stderr,
        )
        return 1
    ids_pinned = parse_ids(text_pinned)
    ids_head = parse_ids(text_head)
    if len(ids_head) < SANITY_FLOOR:
        print(
            f"[중단] upstream 포맷 변경 가능성: {len(ids_head)}개만 매칭됨 "
            f"(기대 ≥{SANITY_FLOOR}). 전부 '신규'로 오보될 위험이 있어 "
            "중단합니다.",
            file=sys.stderr,
        )
        return 1
    print(build_report(ledger, ids_pinned, ids_head, head_sha, head_date))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
