# memory-templates/

`~/.claude/projects/<host-slug>/memory/`에 강제로 박을 auto-memory 템플릿. 호스트별로 `<host-slug>`가 달라 dotfiles 동기화로 직접 복제하기 어려운 메모리를 repo에 source of truth로 두고, 동기화 스크립트로 idempotent 반영한다.

## 파일 구성

- `<filename>.md` — 메모리 본문. frontmatter(`name`, `description`, `metadata.type`) + 본문 구조 그대로. 대상 디렉토리에 같은 이름으로 복사된다.
- `MEMORY-index.md` — 대상 `MEMORY.md`에 idempotent append할 인덱스 라인 모음. 한 줄에 한 entry. 형식: `- [Title](filename.md) — short description`.

## 사용

```bash
bash scripts/sync-memory-templates.sh
```

`~/.claude/projects/` 아래에서 host-slug 디렉토리를 자동 검출하고, 템플릿 파일은 diff/prompt 방식으로 복사, 인덱스 라인은 idempotent append한다. 디렉토리가 여러 개일 때는 첫 인자로 slug 명시:

```bash
bash scripts/sync-memory-templates.sh -home-jay--claude
```

## 동기화 정책

- 본 디렉토리의 메모리 파일은 **source of truth**. 환경별로 본문이 달라지면 본 디렉토리 쪽을 기준으로 정리.
- 환경별로 자연 누적되는 일반 memory(예: 호스트별 history 메모리)는 본 디렉토리에 두지 않는다 — 통합 정책·전역 feedback만.
- 신규 템플릿 추가 시 `MEMORY-index.md`에도 대응 라인을 같이 추가.
