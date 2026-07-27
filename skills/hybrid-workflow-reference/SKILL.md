---
name: hybrid-workflow-reference
description: Index of the hybrid workflow's deferred reference files — effort scoring and escalation rationale, Implementation Unit granularity, brainstorming rigor-probe lenses, and the memory/documentation tier table. Use when a routing call is non-obvious, when grouping U-IDs or choosing serial vs parallel in ce-plan/ce-work, when brainstorming product-facing work, or when deciding where a spec, plan, solution, or memory file belongs. Read only the one file this index points to.
---

# Hybrid workflow — deferred reference (index)

`~/.claude/rules/hybrid-workflow.md` is the resident source of truth; these hold the detail
it defers. **Read only the one row you need** — each file is self-contained. Paths are under
`~/.claude/skills/hybrid-workflow-reference/`.

| Need | Read |
| --- | --- |
| Effort routing call is non-obvious; build carve-out; when to escalate | `references/scoring.md` (§3·§4) |
| Grouping Implementation Units; serial vs parallel in `/ce-work` | `references/units.md` (§6) |
| Brainstorming **product-facing** work — the 5 rigor-probe lenses | `references/brainstorming.md` (§7) |
| Where a spec, plan, solution, or memory file belongs | `references/tiers.md` (§9) |

Deliberately absent: the routing quick card (resident, settles routine calls with no load),
reviewer dispatch (§5 — fully resident in the quick card, nothing left to defer), and the
brainstorming opener (hook-injected at the moment it is needed). Do not copy any of them
into these files.
