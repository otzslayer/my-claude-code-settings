# Development Guidelines

## Mandatory Skill Protocol

When a relevant skill exists, call the `Skill` tool **before proceeding**. Available skills are auto-listed in session context with their own trigger descriptions — invoke via `Skill(skill="...")`. Only what those descriptions do **not** cover is listed below.

- The `superpowers` SessionStart hook already injects `using-superpowers` on every startup / `/clear` / `/compact`. **Never** call `Skill(skill="superpowers:using-superpowers")` explicitly.
- `superpowers:subagent-driven-development` already dispatches the code reviewer internally for each task and for the final branch review — do **not** also run `requesting-code-review` as a separate pipeline stage. That skill is for standalone review requests only.
- `superpowers:brainstorming` writes its spec to `docs/superpowers/specs/`.

## Core Principles

`Understand → Test (RED) → Implement (GREEN) → Refactor → Commit`
YAGNI. Touch only what's needed. Tests pass = Done. Priority: **Testability → Readability → Consistency → Simplicity → Reversibility**
See `~/.claude/rules/karpathy-principles.md` for full detail.

## Process

### Scope Clarification (Before Starting — MANDATORY)

When any part of a task is ambiguous or admits multiple interpretations, **confirm scope before starting work**. Never fill gaps with assumptions. Ask with `AskUserQuestion` and explicit options, never free-form; state each option's tradeoff (scope of effect, side effects, reversal cost) in a line, and label a recommendation "(Recommended)".

Skip only when the instruction admits one interpretation and the change is trivial, or when the scope was already resolved in the immediately preceding turn. If new ambiguity surfaces mid-task, stop immediately and ask. Do not "proceed for now and confirm later."

### Planning Trigger

Run the plan stage (`superpowers:writing-plans`) before starting when **any** of these holds:

- Spans 3+ files
- Requires an architectural decision (new module/pattern)
- Introduces a new dependency
- Modifies a public API or data schema
- User explicitly requests planning

**Exempt** — obvious changes where existing tests pass as-is (type annotations only, ruff auto-fixes, single-file rename with no behavior change, comment/docstring cleanup, version bumps, refactors of a few dozen lines): skip the spec, plan, and TDD stages and go straight to implementation. Run the test suite once after the change anyway. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

**Plan Persistence (MANDATORY)**: `superpowers:writing-plans` → `docs/plans/YYYY-MM-DD-<feature>.md` (**override** the skill's `docs/superpowers/plans/` default; only `brainstorming` specs live under `docs/superpowers/`) → `superpowers:subagent-driven-development` with the plan file as the only input. **NEVER write implementation code inline in the planning session** — SDD implements, through fresh subagents.

**NEVER delete a plan file, not even after the work ships.** Keep `docs/plans/` **git-tracked** in project repos. `~/.claude` is the single exception: it is a public repo, so `.gitignore` keeps the directory untracked there and the file lives in the working tree only.

Whether to `/clear` between planning and building is a judgment call you propose, not a fixed rule: `/clear` when the plan has roughly 5+ tasks or the planning session accumulated many discarded options (the SDD coordinator inherits all of it), same session when the plan is small. Recommend one side with the reason in a line; the user decides. Plan Mode (Shift+Tab) is read-only analysis, not a stage of this pipeline — `writing-plans` needs `Write`.

## TODO Management (Per-project)

Track deferred follow-up work in the project's `TODO.md` (project root —
this is per-project, not global):
- Add items discovered during planning or implementation
- Mark completed items with `- [x]`
- Review `TODO.md` before declaring the task fully complete

## Tools & References

### RTK (Token Optimizer)
@RTK.md
