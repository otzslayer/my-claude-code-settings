# Compound + Superpowers Hybrid Workflow

Operating rules binding Superpowers · Compound Engineering · CodeGraph · RTK · .remember into a single 7-stage pipeline. This document is the source of truth for the pipeline. §3·§4, §6, and §7 are stage-scoped or rationale-heavy, so their detail lives in one-topic files under the `hybrid-workflow-reference` skill's `references/` rather than in context every turn; what stays here is a routing quick card plus a pointer naming the exact file to read.

---

## 7-Stage Pipeline (§1, compressed)

Stage **structure** (phases, `/clear` boundaries) is fixed. Model·effort is not fixed per stage — each task is scored against the routing quick card below.

```
Phase 1: Spec  (model·effort via complexity scoring — §3)
  superpowers:brainstorming  (95% confidence opener at the start — §7)
  → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
  → user review · approval
       │
       ▼  /clear
Phase 2: Plan  (when the Plan Mode trigger is met)
  1. non-plan-mode: /ce-plan  (parallel research + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: query docs/solutions/ — only when 3+ files)
              → docs/plans/<draft>.md
  2. ce-doc-review  (AUTOMATIC as ce-plan's Phase 5.3.8, headless, md-only; reviewer models per the plugin's own tiering)
  3. (optional, manual) plannotator annotate docs/plans/<file> — human browser pass if desired; no Approve button (close w/o feedback = approve; feedback = address on same file); not a mandatory gate, /clear does not block on it
  4. /clear  (do NOT implement inline in the planning session)
       │
       ▼  fresh context, plan file as input
Phase 2': Build  (single session across Phase 2'–3)
  6. superpowers:test-driven-development  (RED → GREEN → REFACTOR, trivial-case exemption)
  7. /ce-work <plan-path>  (built-in worktree · parallel safety; assess blast radius with codegraph_impact before Edit)
  8. /ce-code-review  (reviewer models per the plugin's own tiering, no session model switch)
       │
       ▼
Phase 3: Verify · Learn · Ship
  9. superpowers:verification-before-completion
       (uv run ty check / ruff check --fix / ruff format / pytest -v)
  10. /ce-compound mode:headless  (Full, docs/solutions/<problem>.md only)
  11. superpowers:finishing-a-development-branch  (Korean commit format)
```

**Phase 2 note (§1 — ce-plan runs in non-plan-mode)**:

- ce-plan core work (plan-file `Write`, ce-doc-review autofix) runs in **non-plan-mode** — Plan Mode blocks both.
- `superpowers:writing-plans` is **no longer** the full pipeline's plan stage — `/ce-plan` is. If the user asks for writing-plans while in Plan Mode, point them to `/ce-plan`.
- Review still happens: ce-doc-review runs automatically on the canonical file (Phase 5.3.8). A human browser pass via `plannotator annotate docs/plans/<file>` is **optional and manual** — run it from the terminal or Claude Code if you want one. It has no Approve button: closing without feedback counts as approval, and any feedback you leave is addressed on the same file. It is not a mandatory gate and nothing blocks `/clear` on its result. The annotated artifact **is** the canonical `docs/plans/` file (no `~/.claude/plans/` copy), so ce-doc-review's autofixes are never overwritten by re-pasted plan text.
- The general Plan Mode `ExitPlanMode` path (with its `PermissionRequest` plannotator gate and `~/.claude/plans/` promotion) still serves non-ce-plan work.
- **Korean-prose enforcement** (`~/.claude/settings.json`): a `PreToolUse` `Write|Edit` hook on `docs/plans/*.md` injects the Korean-prose requirement at plan-write time (the `docs/plans/` body is Korean prose; code, identifiers, file paths, and frontmatter keys/enum values stay English).
- Narrow carve-out for ce-plan's own execution only. The general "Plan Mode before complex work" discipline (CLAUDE.md) governs elsewhere.

---

## Effort routing (§3–§5 quick card)

The model is fixed at **Opus 5** — scoring sets `effort` only. This card settles routine calls on its own. When one is non-obvious, read `~/.claude/skills/hybrid-workflow-reference/references/scoring.md` (§3 scoring rationale, §4 escalation/re-run gate).

**Score (§3)** — at every `/clear` boundary, new task, and subagent dispatch. `base + additive signals`, capped at 10.

- base: mechanical/execution 1 · standard implementation 3 · open-ended reasoning (design, brainstorming, root-cause debugging) 5
- add once each: file count (2 → +1 · 3–5 → +2 · 6+ → +3, single matching tier only) · new module/pattern/architectural decision +2 · new dependency +1 · public API or data schema change +2 · cross-cutting concern (concurrency, security, migration) +2 · substantive ambiguity +2

**Band** — the score maps to `effort`. Ceiling is `xhigh`.

| Score | 0–2 | 3–5 | 6–7 | 8–10 |
| --- | --- | --- | --- | --- |
| effort | low | medium | high | xhigh |

- **Round up one band (§4)** when the call is genuinely ambiguous between two bands, or the change has large blast radius / is hard to reverse. A pure base-5 task with no additive signals rounds to `high`. Re-run at a higher band only on a deterministic signal (test/typecheck/verification failure, or mid-task scope overrun) **and** a hard-to-reverse change.
- **Build carve-out (§3)** — `/ce-work` against a finalized plan is **base 1** and planning-time signals are not re-counted → **`medium` regardless of file count**. Escalate only reactively, never on plan scope.
- **Reviewers (§5)** — reviewer model selection belongs to the plugin skill (`ce-code-review`, `ce-doc-review`): follow its own tiering and do not override it per reviewer. **Do NOT edit the plugin skills either** — `~/.claude/plugins/...` is machine state, overwritten on update. What this document does own: never switch the session model for review dispatch (cache reload cost), and note that `ce-doc-review` runs headless inside `/ce-plan`'s own session, so there is no `/clear` boundary to switch at anyway. Effort is not settable per `Agent` dispatch — reviewers inherit the dispatching session's.
- **Applying it (§4)** — the main agent cannot switch its own effort mid-session: announce the scored result and guide the user's `/effort`, never enforce. `Agent`-tool dispatch takes `model` only (effort inherits from the dispatching session); `Workflow` `agent()` takes both.
- Global resting default: `model` is Opus 5 (1M context) — set via `/model`, not a `settings.json` key — and `effortLevel: high` in `~/.claude/settings.json`. `xhigh` is per-task only, never a resting default.

---

## Unit granularity & execution strategy (§6 — token discipline under 1-hour caching)

Two defaults: **coarse Implementation Units** in `/ce-plan`, **serial subagents** in `/ce-work` — spawn count, not per-token price, is the dominant reducible cost. Do not fragment a cohesive change (shared files, types, dependency chains) into fine-grained units just to make the plan look granular. When departing from either default, read `~/.claude/skills/hybrid-workflow-reference/references/units.md` for the full §6 rationale and the accepted trade-off.

---

## 95% confidence opener · rigor-probe lenses (§7 — Phase 1)

The opener utterance and the operating contract (one question at a time, do not move to design below 95% confidence) are injected by `hooks/workflow-stage-inject.sh` the moment `superpowers:brainstorming` is invoked — nothing to load. For **product-facing** work only, read `~/.claude/skills/hybrid-workflow-reference/references/brainstorming.md` for the 5 rigor-probe lenses' definitions; skip it for refactors, documentation, and tooling.

---

## Triggers (§8)

**Full pipeline activation** (same as the Plan Mode trigger) — any one of:

- 3+ file changes
- New module · pattern · architectural decision
- New dependency added
- Public API or data schema change
- Explicit user request ("design this properly", "make a plan")

**Exemption** (skip Phases 1·2, straight to Phase 2'; TDD also exempt):

- Adding type annotations only
- ruff auto-fixes
- Single-file rename (no behavior change)
- Comment/docstring cleanup
- Bumping dependency versions only
- Obvious refactors of one to a few dozen lines (existing tests pass as-is)

These typically land in the 0–2 band (guide the switch if the session differs). Run `pytest` once after the change even under exemption. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

**Partial activation**:

- Broad README update → Phase 1 + Phase 3 (no build stage; score each phase)
- eval result analysis/regression → only Phase 3's `/ce-compound` (artifacts/\*.csv as input; typically scores low)

---

## Memory write boundaries (§9)

**NEVER auto-propagate into Tier 0/1** — `~/.claude/CLAUDE.md`, `~/.claude/rules/`, and `~/.claude/projects/.../memory/` are user-manual-only; `/ce-compound` writes Tier 3 (`docs/solutions/`) exclusively, and the user manually promotes anything worth keeping. This prohibition stays resident; it is not deferred.

---

## Errors / edge cases (§10)

| Situation | Policy |
| --- | --- |
| optional manual plannotator pass | `plannotator annotate docs/plans/<file>` is optional (§1 Phase 2 note) — run it manually (terminal or Claude Code) for a human browser pass. No Approve button: closing without feedback counts as approval; address any feedback you leave on the same file. Not a gate; `/clear` does not block on it |
| ce-work parallel subagent worktree conflict | ce-work's built-in policy (abort → retry serially) |
| ce-compound headless misclassification | docs/solutions/ is git tracked; user manually corrects·deletes |
| ce-compound token overflow | Pass only summary·headers as input, leverage RTK compression |
| docs/solutions/ empty or ≤2 files | Skip ce-learnings-researcher — querying in a low-signal state injects noise into the plan |
| TDD exemption call ambiguous | Confirm via `AskUserQuestion` |
