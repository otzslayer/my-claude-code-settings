# 3-Tier Boundaries

## ✅ Always (Auto-execute)

### Code Quality
- Run tests before committing
- Run linters/formatters
- Run type checker (`uv run ty check`; fall back to `mypy` only when project pins it)
- Add type hints
- Write docstrings for public functions

### Security
- Manage secrets via environment variables
- Validate user input (Pydantic)
- Use parameterized SQL queries
- Exclude sensitive info from error messages

### Patterns
- Follow existing code patterns
- Adhere to project naming conventions
- Add proper error handling
- Use logging (no print statements)

### Surgical Changes
- Remove imports/variables/functions that YOUR changes made unused
- Match existing code style

### Tool Usage (token-optimized)
- **Code intelligence (read)**: CodeGraph MCP — `codegraph_explore` 우선 (PRIMARY: NL 질문 또는 심볼/파일명 → 관련 심볼 소스를 파일별로 한 번에, Read 대체). 보조: `codegraph_search`(이름→위치만), `codegraph_node`(단일 심볼 전체 소스·시그니처, 오버로드 처리)
- **Code relationships**: CodeGraph `codegraph_callers`(누가 X를 호출) / `codegraph_callees`(X가 무엇을 호출) / `codegraph_impact`(X 변경 시 영향 범위 — 리팩토링 전 필수). grep으로 못 따라가는 동적 디스패치까지 추적
- **Project layout**: CodeGraph `codegraph_files` (인덱싱된 파일 트리·심볼 수 — Glob보다 빠름)
- **Text/regex 검색**: `Grep` 유지 — CodeGraph는 심볼 그래프라 문자열/정규식 검색은 하지 않음
- **File/dir lookup**: `Glob` (파일명·글롭) / `Bash(ls)` (디렉토리 나열) — `codegraph_files`가 못 잡는 비코드 파일·특정 경로
- **Code edits**: 표준 `Edit`/`Write`가 **주 경로** — CodeGraph는 읽기 전용(편집 도구 없음). 편집 *전*에 `codegraph_impact`/`codegraph_callers`로 blast radius부터 파악 ("consult BEFORE editing, not during"). 인덱스는 파일 워처가 ~1초 내 자동 갱신 — 수동 갱신 불필요
- **ce-plan 리서치 단계**: CodeGraph `codegraph_explore`·`codegraph_callers`·`codegraph_impact`로 코드베이스 패턴·의존성 자동 수집 (병렬 리서치 에이전트 보조)
- **ce-work 구현 단계**: 편집 전 `codegraph_impact`로 영향 범위 확인 → `Edit`로 변경
- **Knowledge graph (broad)**: `/graphify` — 광범위 네비게이션·아키텍처 개요. 심볼 단위 질의("X가 뭐냐 / 누가 X를 호출하나 / X 바꾸면 뭐가 깨지나")는 CodeGraph
- **Read**: 비코드 파일(`.md`, `.json`, `.toml`, `.yaml`)이나 `codegraph_explore`가 못 잡는 코드 영역 확인용
- **Never** `cat`/`head`/`tail`/`sed`/`awk`

## ⚠️ Ask First (Require Approval)

### Structural
- Database schema changes
- Adding new dependencies
- Modifying existing API interfaces
- Reorganizing file/folder structure

### Configuration
- CI/CD configuration modifications
- Environment configuration file changes
- Build script modifications
- Docker configuration changes

### Deletion
- Removing existing features
- Replacing libraries
- Removing legacy code
- Deleting test cases

### External
- Adding external API integrations
- New service dependencies
- Infrastructure change proposals

## 🚫 Never (Strictly Forbidden)

### Security
- Never commit secrets/API keys
- Never hardcode passwords
- Never bypass security validation
- Never log sensitive data

### Code Quality
- Never use `--no-verify`
- Never delete/disable failing tests
- Never commit non-compiling code
- Never modify `node_modules/`, `vendor/`, `.venv/`

### Process
- Never change production config without approval
- Never make assumptions without verification
- Never repeat same approach after 3 failed attempts
- Never proceed while ignoring errors

### Surgical Changes
- Never "improve" adjacent code unrelated to task
- Never refactor things that aren't broken
- Never delete pre-existing dead code unless asked
- Never fix unrelated bugs without reporting first

## Boundary Violation Response
1. Stop immediately
2. Report which boundary was violated
3. Suggest alternatives
4. Wait for approval
