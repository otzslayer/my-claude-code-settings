# Development Guidelines

## Instruction Priority

Resolve conflicts in this order:

1. Direct user request (current message)
2. This `CLAUDE.md`
3. Files under `~/.claude/rules/`
4. Default Claude Code behavior

## Mandatory Skill Protocol

When a relevant skill exists, call the `Skill` tool **before proceeding**.

### Session Start — `using-superpowers` is auto-injected (do NOT re-invoke)
The `superpowers` SessionStart hook already injects `using-superpowers` on every startup / `/clear` / `/compact`, so **never** call `Skill(skill="superpowers:using-superpowers")` explicitly. The skill-check discipline still applies to every **other** skill (see the table below).

### High-Priority Workflow Skills

| Trigger | Skill |
|---------|-------|
| New feature / component / behavior change | `superpowers:brainstorming` → `docs/superpowers/specs/` |
| Multi-step implementation task | `superpowers:writing-plans` → `docs/plans/`, then `/clear` |
| Plan execution | `superpowers:subagent-driven-development` |
| Bug or failing test | `superpowers:systematic-debugging` |
| Implementation work | `superpowers:test-driven-development` (trivial-case exemption) |
| Code review (standalone request, outside plan execution) | `superpowers:requesting-code-review` |
| Before claiming task complete | `superpowers:verification-before-completion` |
| Learning accumulation (after work completes) | `/ce-compound mode:headless` |
| Commit · push · PR | `superpowers:finishing-a-development-branch` |
| Writing/editing Python (`.py`) | `python-coding-style` |
| New Python project / directory layout | `python-architecture` |

Domain skills (FastAPI, LangChain, etc.) layer on top when relevant. Available skills are auto-listed in session context — invoke via `Skill(skill="...")`.

`superpowers:subagent-driven-development` already dispatches the code reviewer internally for each task and for the final branch review — do **not** also run `requesting-code-review` as a separate pipeline stage. That row is for standalone review requests only.

**Model · effort**: the user sets both directly via `/model` and `/effort`. The agent does not score task complexity and does not propose switching.

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

### Planning Trigger

Run the plan stage (`superpowers:writing-plans`) before starting when **any** of these holds:

- Spans 3+ files
- Requires an architectural decision (new module/pattern)
- Introduces a new dependency
- Modifies a public API or data schema
- User explicitly requests planning

**Exempt** — skip the spec and plan stages, go straight to implementation (TDD is also exempt):

- Adding type annotations only
- ruff auto-fixes
- Single-file rename with no behavior change
- Comment/docstring cleanup
- Dependency version bumps only
- Obvious refactors of one to a few dozen lines where existing tests pass as-is

Run the test suite once after the change even under the exemption. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

**Plan Persistence (MANDATORY)**: `superpowers:writing-plans` → `docs/plans/YYYY-MM-DD-<feature>.md` → `/clear` → fresh session, `superpowers:subagent-driven-development` with the plan file as the only input. **NEVER implement inline in the same planning session.**

**The plan file is permanent — NEVER delete it, not even after the work ships.** It is the record of why the change looks the way it does, and the only artifact that survives the `/clear` between planning and building. In a project repo, keep `docs/plans/` **git-tracked** so it survives `git clean` and machine moves. **`~/.claude` is the single exception**: it is a public repo, so `.gitignore` keeps `docs/plans/` untracked there — the no-delete rule still holds, the file just lives in the working tree only.

`superpowers:writing-plans` defaults to `docs/superpowers/plans/`; **override it to `docs/plans/`**. Only specs from `superpowers:brainstorming` live under `docs/superpowers/`.

Plan Mode (Shift+Tab) is still available for read-only analysis, but it is not a stage of this pipeline — `writing-plans` writes the plan file with `Write`, which Plan Mode blocks.

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

Extended guidelines live in `~/.claude/rules/` and are loaded in full alongside this file.

Active hooks live in `~/.claude/settings.json` under `hooks` (source of truth — view with `/hooks`).

## TODO Management (Per-project)

Track deferred follow-up work in the project's `TODO.md` (project root —
this is per-project, not global):
- Add items discovered during planning or implementation
- Mark completed items with `- [x]`
- Review `TODO.md` before declaring the task fully complete

## Tools & References

### RTK (Token Optimizer)
@RTK.md

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tools** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them. `codegraph_node` returns one symbol's source + callers, or reads a whole file with line numbers. If the tools are listed but deferred, load them by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` and `codegraph node <symbol-or-file>` print the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
