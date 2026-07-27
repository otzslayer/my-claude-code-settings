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
The `superpowers` SessionStart hook already injects the full `using-superpowers` skill into context on every startup / `/clear` / `/compact`, and it stays present for the whole session. Do **not** call `Skill(skill="superpowers:using-superpowers")` explicitly — a manual call only re-inserts identical content and needlessly fires the `workflow-stage-inject.sh` PostToolUse hook. Subagents (Task tool) must ignore it entirely (per the skill's own `<SUBAGENT-STOP>`). The skill-check discipline still applies to every **other** skill: when a relevant skill exists, invoke it before proceeding (see the table below).

### High-Priority Workflow Skills

| Trigger | Skill |
|---------|-------|
| New feature / component / behavior change | `superpowers:brainstorming` — 95% confidence opener. The resulting spec always continues into the plan stage via `/ce-plan` (this pipeline takes priority even if the entry skill offers its own plan tool) |
| Multi-step implementation task | `ce-plan` (core work runs in non-plan-mode — see Plan Persistence below) |
| Plan execution | `ce-work <plan-path>` |
| Bug or failing test | `superpowers:systematic-debugging` |
| Implementation work | `superpowers:test-driven-development` (trivial-case exemption) |
| Code review | `ce-code-review` (reviewer model branching — see hybrid-workflow.md §5) |
| Before claiming task complete | `superpowers:verification-before-completion` |
| Learning accumulation (after work completes) | `/ce-compound mode:headless` |
| Commit · push · PR | `superpowers:finishing-a-development-branch` |
| Writing/editing Python (`.py`) | `python-coding-style` |
| New Python project / directory layout | `python-architecture` |

Domain skills (FastAPI, LangChain, etc.) layer on top when relevant. Available skills are auto-listed in session context — invoke via `Skill(skill="...")`. Model·effort for every row above is computed by scoring the task's complexity, not fixed per skill — see the policy below.

**Model · effort policy**: The agent cannot switch its own model mid-session, so at each task or `/clear` boundary, score the task's complexity (base + additive signals → band → model·effort — see "Complexity scoring" §3 in `~/.claude/rules/hybrid-workflow.md`) and announce the result; if it differs from the current setting, guide the switch via `/model`·`/effort` — announce and confirm, never enforce. **Exception — ce-code-review / ce-doc-review**: no session switch (avoids a costly in-session cache reload); their reviewer subagents are currently pinned to `model=opus` across the board — the adversarial-vs-rest opus/sonnet split is collapsed while sonnet is suspended from routing (hybrid-workflow.md §3/§5) — with effort inherited from the dispatching session. Full definition: the "Model recalibration" (§2), "Complexity scoring" (§3), "Escalation policy" (§4), and "Reviewer branching" (§5) sections in `~/.claude/rules/hybrid-workflow.md`.

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

**Carve-out — ce-plan's own execution runs in non-plan-mode**: the general Plan Mode discipline above still governs *whether* to plan and covers Plan Mode itself. But ce-plan's core work — writing `docs/plans/<draft>.md` and ce-doc-review's autofix — runs in **non-plan-mode**, because Plan Mode blocks both `Write` and autofix. This does not weaken review: ce-doc-review still runs automatically on the canonical file (Phase 5.3.8, step 2 below). A human browser pass via `plannotator annotate docs/plans/<file>` is optional and manual (step 3 below) — not a mandatory gate. See `~/.claude/rules/hybrid-workflow.md` (Phase 2 note, §1) for the full mechanism rationale.

**Plan Persistence (MANDATORY — Complex tasks)**:

1. Author `docs/plans/<draft>.md` via `/ce-plan` in non-plan-mode (answer ce-plan's interactive questions; create the `docs/plans/` directory if it doesn't exist)
2. ce-doc-review runs automatically as ce-plan's Phase 5.3.8 (headless, md-only; reviewer model branching per hybrid-workflow.md §5)
3. (Optional) For a human browser pass, run `plannotator annotate docs/plans/<file>` manually (terminal or Claude Code) on the canonical plan file. There is no Approve button — closing without feedback counts as approval; if you leave feedback, address it on the same `docs/plans/YYYY-MM-DD-<summary>.md` file (reuse it, keep the original date). Not a mandatory gate — `/clear` does not block on it.
4. `/clear` → execute via `/ce-work <plan-path>` in a new session (score the build task's complexity per hybrid-workflow.md §3 and guide the resulting `/model`·`/effort` switch)
5. NEVER implement inline in the same planning session — this wastes planning context tokens

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
