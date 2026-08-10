# Development Guidelines

## Mandatory Skill Protocol

When a relevant skill exists, call the `Skill` tool **before proceeding**. Available skills are auto-listed in session context with their own trigger descriptions — invoke via `Skill(skill="...")`.

## Core Principles

`Understand → Test (RED) → Implement (GREEN) → Refactor → Commit`
YAGNI. Touch only what's needed. Tests pass = Done. Priority: **Testability → Readability → Consistency → Simplicity → Reversibility**
See `~/.claude/rules/karpathy-principles.md` for full detail.

## Process

### Scope Clarification (Before Starting — MANDATORY)

When any part of a task is ambiguous or admits multiple interpretations, **confirm scope before starting work**. Never fill gaps with assumptions. Ask with `AskUserQuestion` and explicit options, never free-form; state each option's tradeoff (scope of effect, side effects, reversal cost) in a line, and label a recommendation "(Recommended)".

Skip only when the instruction admits one interpretation and the change is trivial, or when the scope was already resolved in the immediately preceding turn. If new ambiguity surfaces mid-task, stop immediately and ask. Do not "proceed for now and confirm later."

## TODO Management (Per-project)

Track deferred follow-up work in the project's `TODO.md` (project root —
this is per-project, not global):
- Add items discovered during planning or implementation
- Mark completed items with `- [x]`
- Review `TODO.md` before declaring the task fully complete

## Tools & References

### RTK (Token Optimizer)
@RTK.md

# graphify
- **graphify** (`~/.claude/skills/graphify/SKILL.md`) - any input to knowledge graph. Trigger: `/graphify`
When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.
