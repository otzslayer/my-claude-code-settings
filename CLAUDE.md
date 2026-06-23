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
| New feature / component / behavior change | `superpowers:brainstorming` — 95% confidence opener. The resulting spec always continues into the plan stage via `/ce-plan` (this pipeline takes priority even if the entry skill offers its own plan tool) | Opus · `xhigh` |
| Multi-step implementation task (within Plan Mode) | `ce-plan` | Opus · `xhigh` |
| Plan execution | `ce-work <plan-path>` | Sonnet · `high` |
| Bug or failing test | `superpowers:systematic-debugging` | Opus · `xhigh` |
| Implementation work | `superpowers:test-driven-development` (trivial-case exemption) | Sonnet · `high` |
| Code review | `ce-code-review` | Opus · `xhigh` (reviewer subagents / session stays on Sonnet) |
| Before claiming task complete | `superpowers:verification-before-completion` | Sonnet · `high` |
| Learning accumulation (after work completes) | `/ce-compound mode:headless` | Sonnet · `high` |
| Commit · push · PR | `superpowers:finishing-a-development-branch` | Sonnet · `high` |
| Writing/editing Python (`.py`) | `python-coding-style` | (keep current stage's model) |
| New Python project / directory layout | `python-architecture` | (keep current stage's model) |

Domain skills (FastAPI, LangChain, etc.) layer on top when relevant. Available skills are auto-listed in session context — invoke via `Skill(skill="...")`.

**Model · effort policy**: The column above is the recommended execution model and reasoning effort for each stage. **Since the main agent cannot switch its own model mid-session**, at the start of each stage (especially a new session after `/clear`), announce that stage's recommended model · effort and, if it differs from the current setting, guide the user to switch via `/model`·`/effort` before proceeding (never enforce — announce and confirm only). The current global default is `model: Opus`·`effortLevel: xhigh`, so Opus stages need no switch; when entering a Sonnet stage, guide `/model sonnet`·`/effort high`. **Exception — ce-code-review**: it runs inside Phase 2', not at a `/clear` boundary, so the session model does not change (session stays on Sonnet, avoiding the cache cost of an in-session switch). "Opus xhigh" here means the 6+ reviewer subagent level is recommended. For the formal definition and rationale, see the "Per-stage model policy" section in `~/.claude/rules/hybrid-workflow.md`.

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

1. Enter Plan Mode — press Shift+Tab, **or** the agent calls the `EnterPlanMode` tool (which carries a user-approval gate). Unlike model·effort switches (which the agent cannot perform mid-session), Plan Mode entry **can** be triggered by the agent itself via this tool. **ce-plan operates only inside Plan Mode** — it is the precondition for the plannotator gate. So if you are about to invoke `/ce-plan` and are not already in Plan Mode, call `EnterPlanMode` FIRST, then invoke ce-plan. (The `workflow-stage-inject.sh` `*ce-plan` hook re-asserts this at runtime **when ce-plan is invoked via the Skill tool**; a user-typed `/ce-plan` slash command may load without a Skill call and bypass the hook, so this step-1 guidance — always in context at session start — is the primary guarantee, with the hook as a supplementary backstop.)
2. Author `docs/plans/<draft>.md` via `/ce-plan` (answer ce-plan's interactive questions; create the `docs/plans/` directory if it doesn't exist)
3. Call `ExitPlanMode` — include the ce-plan result path and summary in the plan argument
4. The plannotator hook fires automatically → annotate and approve in the browser UI
5. Apply annotations or approve → final save to `docs/plans/YYYY-MM-DD-<summary>.md` (on revision, reuse the same file and keep the original date)
6. `/clear` → execute via `/ce-work <plan-path>` in a new session (Plan is Opus·`xhigh`, Build is Sonnet·`high` — at new-session start, guide the `/model sonnet`·`/effort high` switch)
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
- `hybrid-workflow.md` — Operating rules for the Compound + Superpowers hybrid pipeline
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
@RTK.md

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tools** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them. `codegraph_node` returns one symbol's source + callers, or reads a whole file with line numbers. If the tools are listed but deferred, load them by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` and `codegraph node <symbol-or-file>` print the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

### CodeGraph — relationships & impact (indexed repos only)

- Relationships/impact (symbol-level): `codegraph_callers` / `codegraph_callees` / `codegraph_impact` (MCP), or shell `codegraph callers|callees|impact <symbol>`. Before refactoring, check the blast radius with `impact`.
- Project layout: `codegraph_files` (MCP) / `codegraph files` (shell) — takes no argument, the indexed file tree.
- Read-only — make edits with `Edit`/`Write`, do text/regex search with `Grep`.
- Symbol-level queries go to CodeGraph; broad navigation and architecture overview go to `graphify` (below).

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
