# Development Guidelines

## Mandatory Skill Protocol

When a relevant skill exists, call the `Skill` tool **before proceeding**. Available skills are auto-listed in session context with their own trigger descriptions — invoke via `Skill(skill="...")`.

### Korean wording produced by a skill (MANDATORY)

Whenever running a skill leads you to write Korean wording that lands in a file or a deliverable — a document, a spec value, a diagram title or label, a commit message, a caption — run it through `polish-korean` (text mode) **before** it is written or built. Do this every time; never skip it because the wording is short or reads fine.

Out of scope: conversational replies to the user (the Korean output style already governs those, and polish-korean itself refuses to restyle a sent reply); code identifiers, paths, commands, flags, and quoted source text; and the `polish-korean`, `translate-doc`, and `humanize-korean` skills themselves, which already carry the house style.

## Core Principles

`Understand → Test (RED) → Implement (GREEN) → Refactor → Commit`
YAGNI. Touch only what's needed. Tests pass = Done. Priority: **Testability → Readability → Consistency → Simplicity → Reversibility**
See `~/.claude/rules/karpathy-principles.md` for full detail.

## Tool Calls

When a tool call parameter contains non-ASCII text (Korean, CJK, accented Latin, emoji), emit it as literal UTF-8. Never rewrite it as `\uXXXX` unicode escapes.

This applies to every parameter of every tool, including `Write` content, `Edit` old_string/new_string, `Bash` commands, and MCP tool arguments. Escaped Korean can decode to a different but still-valid syllable, so the corruption saves without raising an error.

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
