# Development Guidelines

## Instruction Priority

Resolve conflicts in this order:

1. Direct user request (current message)
2. This `CLAUDE.md`
3. Files under `~/.claude/rules/`
4. Default Claude Code behavior

## Mandatory Skill Protocol

When a relevant skill exists, call the `Skill` tool **before proceeding**.

### Every Session Start — NO EXCEPTIONS
Call `Skill(skill="superpowers:using-superpowers")` before any file reads or clarifying questions.

### High-Priority Workflow Skills

| Trigger | Skill | Model · effort |
|---------|-------|----------------|
| New feature / component / behavior change | `superpowers:brainstorming` — 95% confidence opener. 산출 spec은 plan 단계에서 항상 `/ce-plan`으로 이어감 (진입 스킬이 자체 plan 도구를 제시해도 이 파이프라인 우선) | Opus · `xhigh` |
| Multi-step implementation task (Plan Mode 안에서) | `ce-plan` | Opus · `xhigh` |
| Plan 실행 | `ce-work <plan-path>` | Sonnet · `high` |
| Bug or failing test | `superpowers:systematic-debugging` | Opus · `xhigh` |
| Implementation work | `superpowers:test-driven-development` (트리비얼 면제) | Sonnet · `high` |
| Code review | `ce-code-review` | Opus · `xhigh` (리뷰어 subagent / 세션은 Sonnet 유지) |
| Before claiming task complete | `superpowers:verification-before-completion` | Sonnet · `high` |
| 학습 누적 (작업 완료 후) | `/ce-compound mode:headless` | Sonnet · `high` |
| 커밋·푸시·PR | `superpowers:finishing-a-development-branch` | Sonnet · `high` |
| Writing/editing Python (`.py`) | `python-coding-style` | (현재 단계 모델 유지) |
| New Python project / directory layout | `python-architecture` | (현재 단계 모델 유지) |

Domain skills (FastAPI, LangChain, etc.) layer on top when relevant. Available skills are auto-listed in session context — invoke via `Skill(skill="...")`.

**Model · effort 정책**: 위 열은 각 단계의 권장 실행 모델과 reasoning effort다. **메인 에이전트는 세션 도중 스스로 모델을 바꿀 수 없으므로**, 각 단계(특히 `/clear` 후 새 세션) 시작 시 그 단계의 권장 모델·effort를 announce하고 현재 설정과 다르면 사용자에게 `/model`·`/effort` 전환을 안내한 뒤 진행한다(강제 금지, 안내·확인만). 현재 글로벌 디폴트는 `model: Opus`·`effortLevel: xhigh`이므로 Opus 단계는 전환 불필요, Sonnet 단계 진입 시 `/model sonnet`·`/effort high`를 안내한다. **예외 — ce-code-review**: Phase 2' 내부라 `/clear` 경계가 아니므로 세션 모델을 바꾸지 않는다(세션 Sonnet 유지, 세션 중 전환의 캐시 비용 회피). "Opus xhigh"는 6+ 리뷰어 subagent 레벨 권장을 뜻한다. 정식 정의·근거는 `~/.claude/rules/hybrid-workflow.md` "단계별 모델 정책" 참조.

## Core Principles

`Understand → Test (RED) → Implement (GREEN) → Refactor → Commit`
YAGNI. Touch only what's needed. Tests pass = Done. Priority: **Testability → Readability → Consistency → Simplicity → Reversibility**
See `~/.claude/rules/karpathy-principles.md` for full detail.

## Process

### Scope Clarification (Before Starting — MANDATORY)

When given a task, **always confirm scope with questions before starting work** if any part is ambiguous or admits multiple interpretations. Never fill gaps with assumptions.

**Question triggers (any of)**:
- The instruction admits multiple interpretations (e.g., "also fix related parts" — what counts as "related"?)
- The scope of application is unclear (specific file / directory / whole project / global)
- Multiple targets are affected and the user may mean only a subset (e.g., "the regression rule" when 3 models exist)
- There are multiple valid storage/placement locations (project vs global, memory vs settings file)
- The intensity of change is unclear (rename only vs signature change vs behavior change)

**How to ask**:
- Use `AskUserQuestion` with explicit options. Do not rely on free-form answers.
- For each option, briefly state the tradeoff (scope of effect, side effects, reversal cost).
- If you have a recommendation, label it "(Recommended)" with a one-line rationale.

**When to skip (clarification not required)**:
- The instruction admits only one interpretation and the change is trivial (typo fix, explicit file + explicit change).
- A follow-up to a task whose scope was already resolved in the immediately preceding turn.

If new ambiguity surfaces mid-task, stop immediately and ask. Do not "proceed for now and confirm later."

### Plan Mode (Shift+Tab)
Before complex tasks: Plan Mode → Analyze → Draft plan → Resolve ambiguities → Implement after approval

**Complex task = any of:**
- Spans 3+ files
- Requires architectural decision (new module/pattern)
- Introduces new dependency
- Modifies public API or data schema
- User explicitly requests planning

**Plan Persistence (MANDATORY — Complex tasks)**:

1. Plan Mode 진입 (Shift+Tab)
2. `/ce-plan`으로 `docs/plans/<draft>.md` 작성 (ce-plan 인터랙티브 질문 응답; `docs/plans/` 디렉토리가 없으면 생성)
3. `ExitPlanMode` 호출 — plan 인자에 ce-plan 결과 경로·요약 포함
4. plannotator hook 자동 발동 → browser UI에서 어노테이션·승인
5. 어노테이션 반영 또는 승인 → `docs/plans/YYYY-MM-DD-<summary>.md` 최종 저장 (revision 시 같은 파일, 원 날짜 유지)
6. `/clear` → 새 세션에서 `/ce-work <plan-path>`로 실행 (Plan은 Opus·`xhigh`, Build는 Sonnet·`high` — 새 세션 시작 시 `/model sonnet`·`/effort high` 전환 안내)
7. NEVER implement inline in the same planning session — this wastes planning context tokens

### When Stuck (Max 3 Attempts)
Document failure → Research alternatives → Question fundamentals → Try different approach

### Before Declaring Done

- [ ] Tests pass (or N/A explicitly stated)
- [ ] Lint/format clean (`ruff check`, `ruff format` for Python)
- [ ] Type check clean (`uv run ty check` for Python — fallback to `mypy` only if project pins `[tool.mypy]` in `pyproject.toml` and has no `[tool.ty]`)
- [ ] No new warnings introduced
- [ ] Every change traces to user's original request
- [ ] Side effects (file paths, env, other modules) verified

## Rules Directory

Extended guidelines in `~/.claude/rules/`:
- `boundaries.md` — Auto/Ask/Never permission tiers, tool-usage policy
- `karpathy-principles.md` — Full principles detail
- `git-workflow.md` — Commit format, branch naming, PR workflow
- `hybrid-workflow.md` — Compound + Superpowers 하이브리드 파이프라인 운영 규칙
- `security.md` — Pre-commit checklist, secret management

Active hooks live in `~/.claude/settings.json` under `hooks` (source of truth — view with `/hooks`).

## TODO Management (Per-project)

Track deferred follow-up work in the project's `TODO.md` (project root —
this is per-project, not global):
- Add items discovered during planning or implementation
- Mark completed items with `- [x]`
- Review `TODO.md` before declaring the task fully complete

## Tools & References

### RTK (Token Optimizer)
@~/.claude/RTK.md

## CodeGraph (symbol-level code intelligence)

CodeGraph는 워크스페이스의 모든 심볼·호출·파일을 인덱싱한 SQLite 지식 그래프(`.codegraph/`)다. 읽기는 sub-millisecond이고, 파일 워처가 쓰기를 ~1초 내 자동 반영하므로 **수동 갱신이 필요 없다**. 코드를 읽거나 수정하기 **전에** 조회한다 (consult BEFORE editing, not during).

Rules:
- 코드 관련 질문("X가 어떻게 동작하나", 아키텍처, "X가/어디 있나", 특정 영역 훑어보기)은 먼저 `codegraph_explore`를 호출한다 — NL 질문 또는 심볼/파일명을 주면 관련 심볼 소스를 파일별로 한 번에 돌려준다(Read 대체). 보통 이 한 번이면 충분하다.
- 이름으로 위치만 찾을 땐 `codegraph_search`, 단일 심볼의 전체 소스·시그니처는 `codegraph_node`.
- 관계는 `codegraph_callers`(누가 X를 호출) / `codegraph_callees`(X가 무엇을 호출) / `codegraph_impact`(X를 바꾸면 무엇이 깨지나 — 리팩토링 전 필수). grep으로 못 따라가는 동적 디스패치(콜백·재렌더 등)까지 추적한다.
- 프로젝트 레이아웃은 `codegraph_files`(인덱싱된 파일 트리·심볼 수 — Glob보다 빠름).
- CodeGraph는 **읽기 전용**이다 — 편집 도구가 없으므로 코드 수정은 표준 `Edit`/`Write`로 한다. 텍스트/정규식 검색도 CodeGraph가 하지 않으므로 `Grep`을 쓴다.
- **CodeGraph vs graphify**: 심볼 단위 질의(무엇/누가 호출/무엇이 깨지나)는 CodeGraph, 광범위 네비게이션·아키텍처 개요는 graphify(아래).

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).

@RTK.md
