# Compound + Superpowers Hybrid Workflow

Operating rules binding Superpowers · Compound Engineering · CodeGraph · RTK · .remember into a single 7-stage pipeline. This document is the source of truth for the pipeline. §6, §7, and §9 are stage-scoped, so their detail lives in the lazily-loaded `hybrid-workflow-reference` skill rather than in context every turn; the sections below point to it where it applies.

---

## 7-Stage Pipeline (§1, compressed)

Stage **structure** (phases, `/clear` boundaries) is fixed. Model·effort is not fixed per stage — each task is scored (see §3) and routed to a band.

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
  2. ce-doc-review  (AUTOMATIC as ce-plan's Phase 5.3.8, headless, md-only; reviewer branching — §5)
  3. (optional, manual) plannotator annotate docs/plans/<file> — human browser pass if desired; no Approve button (close w/o feedback = approve; feedback = address on same file); not a mandatory gate, /clear does not block on it
  4. /clear  (do NOT implement inline in the planning session)
       │
       ▼  fresh context, plan file as input
Phase 2': Build  (single session across Phase 2'–3; ce-code-review reviewer branching — §5)
  6. superpowers:test-driven-development  (RED → GREEN → REFACTOR, trivial-case exemption)
  7. /ce-work <plan-path>  (built-in worktree · parallel safety; assess blast radius with codegraph_impact before Edit)
  8. /ce-code-review  (reviewer branching, no session model switch — §5)
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
- **Korean-prose enforcement** (`~/.claude/settings.json`): a `PreToolUse` `Write|Edit` hook on `docs/plans/*.md` injects the Korean-prose requirement at plan-write time (see §9).
- Narrow carve-out for ce-plan's own execution only. The general "Plan Mode before complex work" discipline (CLAUDE.md) governs elsewhere.

---

## Model recalibration (§2)

Formal definition; model notations in CLAUDE.md and elsewhere refer back here.

| Model | Intelligence | Cost burden | Character |
| --- | --- | --- | --- |
| fable-5 | highest | highest (Anthropic list pricing) | sustained multi-subsystem design/implementation, long agentic chains — genuinely long-horizon work only |
| opus-4.8 | high | moderate-high | complex/open-ended reasoning, architecture, adversarial review |
| sonnet-5 | solid | low list price · **high effective in agentic use** | execution against a finalized artifact (spec/plan) — **currently suspended from routing** (§3 cost inversion) |
| haiku | — | — | **not used** in this pipeline |

- Intelligence: fable > opus > sonnet. **Per-token** cost: sonnet cheapest, fable priciest — but sonnet's **effective** cost inverts above opus on multi-step agentic work (3–4× token/iteration inflation), which is why it is currently out of routing (§3).
- Reserve fable for genuinely complex tasks, not merely long-running ones.

## Complexity scoring (§3)

Every task — main-session work at a `/clear` boundary, and each subagent dispatch — is scored 0–10 (capped) and routed to a band. **Score = base (cognitive character) + additive signals (scope).**

### Base score (cognitive character)

| Character | Base |
| --- | --- |
| Mechanical / execution (build, verify, rename, typing, formatting) | 1 |
| Standard implementation (well-defined feature, bounded bug) | 3 |
| Open-ended reasoning (design, brainstorming, root-cause debugging) | 5 |

### Additive signals (apply once each, when present)

| Signal | Add |
| --- | --- |
| File count: 2 files +1 · 3–5 files +2 · 6+ files +3 (apply only the single matching tier, not cumulatively) | +1 to +3 |
| New module / pattern / architectural decision | +2 |
| New dependency | +1 |
| Public API or data schema change | +2 |
| Cross-cutting concern (concurrency, security, migration) | +2 |
| Substantive ambiguity (requirements branch multiple ways) | +2 |

### Band → model · effort (score-routing ceiling = opus · xhigh)

| Score | Band | Model | Effort |
| --- | --- | --- | --- |
| 0–2 | Trivial / mechanical | opus-4.8 | low |
| 3–5 | Standard | opus-4.8 | medium |
| 6–7 | Moderately hard | opus-4.8 | high |
| 8–10 | Complex | opus-4.8 | xhigh |

- **Boundary rounding rule** (concrete instance of §4's "round up at boundaries"): a pure base-5 task (open-ended reasoning, zero additive signals) lands on 5 — round up to opus·high (not opus·medium), so open-ended reasoning always gets high effort.
- **fable-5 gating**: fable is never reached by raw score (the score can't distinguish "many small signals" from "genuinely long-horizon"). Opt in only via an explicit **long-horizon flag** — sustained design/implementation across subsystems, a long agentic chain, or a task exceeding the opus·xhigh ceiling. Default effort `high`, `xhigh` optional.
- **Build-stage carve-out (ce-work / Phase 2')**: build against a finalized plan scores **base 1** (the plan already absorbed the design judgment). Planning-time signals the plan resolved — file count, new module/pattern, public-API/schema change — are **not re-counted** (re-counting double-prices scope the plan already paid for). Default is **opus·medium regardless of file count** — with all bands on opus, the carve-out now caps *effort* at medium (a big plan does not push build to high/xhigh) rather than downgrading the model tier. File count drives unit *volume* (see Unit granularity). Build escalates to higher effort only reactively via the §4 re-run gate, never pre-emptively on scope. Whenever a finalized plan exists, this settles the build-vs-"well-defined feature" ambiguity in favor of base 1.
- **Global default** (`~/.claude/settings.json`): `model: opus[1m]`, `effortLevel: high` (resting). `xhigh` is reached per-task within the 8–10 band via the score — never a resting default.
- **Sonnet-5 suspended from routing (cost inversion)**: bands 0–5 use opus·low/medium (not sonnet), and §5's non-adversarial reviewers run opus too. Sonnet's per-token discount is erased by 3–4× token/iteration inflation on this pipeline's agentic work, so its *effective* cost sits at or above opus while accuracy sits below (BrowseComp: opus·low $5/67.7% beats sonnet·high $7/64.8%; Artificial Analysis index total: opus-4.8 max $3,753 < sonnet-5 max $6,015; a real agentic run: opus-4.8 70 req/$7.07 vs sonnet-5 309 req/$20.95 — see README). Reintroduce sonnet to the low bands (and the §5 non-adversarial reviewers) only when re-benchmarking shows its cost-per-verified-outcome back below opus at that band.

## Escalation policy (§4)

- **Round up at boundaries (insurance premium)** — break ties by rounding up one band when: scoring is genuinely ambiguous between two adjacent bands (unsure an additive signal applies, or a pure base score lands exactly on a band's top value with no signal to push further — see §3 boundary rounding), **or** the task has large blast radius / is hard to reverse. Tie-breaker for genuine uncertainty only — a clean 7 (already opus·high) is not re-rounded into 8–10.
- **Re-run gate — narrow, objective-signal-first** — re-score/re-run at a higher band only when a deterministic signal fires (test/typecheck/verification failure, **or** mid-task scope discovery — file count, cross-cutting concerns — exceeding the initial band's assumption) **and** the task is hard to reverse. The scope-overrun trigger keeps signal-less work (prose, governance edits) with mid-investigation scope growth inside the gate. Self-reported confidence is a secondary signal only, for areas with no objective signal (design, research).
- **Build-stage escalation is reactive, not scope-priced** — ce-work starts at opus·medium (§3 carve-out) and does **not** escalate on the plan's own scope (file count, new module, API/schema are already priced in). It escalates to higher effort (opus·high/xhigh) only when execution surfaces what the plan did not foresee: a RED→GREEN stall turning into open-ended root-cause debugging (re-scored as base-5 debugging, matching the `systematic-debugging` = opus lineage), or a test/typecheck/verification failure on a hard-to-reverse change per the re-run gate.

### Applying the score

The main agent **cannot switch its own model mid-session** — model·effort changes only via the user's `/model`·`/effort` input or a new session after `/clear`. This shapes each dispatch point:

With the score-based bands now all resolving to opus (§3), `/model` changes only when the fable long-horizon flag fires (or the session isn't already on opus); per-task variation is otherwise carried entirely by `/effort`.

| Dispatch point | Mechanism |
| --- | --- |
| Main session (after scoring, at a `/clear` boundary or new task) | Announce both `/model` and `/effort`, guide the switch — announce and confirm, never enforce |
| `Agent`-tool subagent (reviewers, ce-work workers) | `model` pinned at dispatch; the tool exposes no `effort` parameter, so effort is **inherited from the dispatching session** |
| `Workflow` `agent()` — top-level/orchestrating session only, not a subagent it dispatches | Both `model` and `effort` set per-agent — fully dynamic |

The "opus·high" reviewer notation in §5 is therefore realized as a `model=opus` pin + session-inherited effort, not a pinned effort. At the resting `effortLevel: high`, Agent-tool opus reviewers land near `high` via inheritance; an `xhigh` parent yields an `xhigh` reviewer.

## Reviewer branching (§5)

Review is open-ended adversarial reasoning (base 5) — only the highest-stakes judgment escalates. Effort cannot be set per-dispatch (see "Applying the score"), so only `model` is pinned. **Do NOT edit the plugin skills to achieve this** — `~/.claude/plugins/...` is machine state, overwritten on plugin update; this document is the enforcement point and outranks the skills' built-in model tiering. **Currently the split is collapsed — all reviewers run `model=opus`** because sonnet is suspended from routing (§3 cost inversion); the table below records the intended opus-vs-sonnet split to restore when sonnet is reintroduced.

| Skill | model=opus (adversarial lineage) | model=sonnet (the rest) |
| --- | --- | --- |
| ce-code-review | correctness · security · adversarial | remaining reviewers |
| ce-doc-review | adversarial · security-lens | coherence · feasibility · product-lens · design-lens · scope-guardian |

- `ce-doc-review` runs automatically as ce-plan's mandatory Phase 5.3.8, headless, for every `OUTPUT_FORMAT=md` plan (skipped only for `OUTPUT_FORMAT=html`), inside the same session as `/ce-plan` (no `/clear` boundary to switch models). `ce-code-review` runs in Phase 2'.
- The per-reviewer `model` pin carries the branching regardless. Session model is never switched for review dispatch (avoids a costly cache reload).

---

## Unit granularity & execution strategy (§6 — token discipline under 1-hour caching)

Two defaults: **coarse Implementation Units** in `/ce-plan`, **serial subagents** in `/ce-work` — spawn count, not per-token price, is the dominant reducible cost. Before grouping U-IDs or choosing serial vs parallel fan-out, invoke `Skill(skill="hybrid-workflow-reference")` for the full §6 rationale and the accepted trade-off.

---

## 95% confidence opener (§7 — Phase 1 first turn, model utterance)

Entering `superpowers:brainstorming` **requires** invoking `Skill(skill="hybrid-workflow-reference")` first — it holds the verbatim Korean opener utterance, the operating contract (one question at a time, do not stop below 95% confidence), and the 5 rigor-probe lenses for product-facing work.

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

These typically land in the 0–2 band per §3 (guide the switch if the session differs). Run `pytest` once after the change even under exemption. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

**Partial activation**:

- Broad README update → Phase 1 + Phase 3 (no build stage; score each phase per §3)
- eval result analysis/regression → only Phase 3's `/ce-compound` (artifacts/\*.csv as input; typically scores low)

---

## Memory · documentation tiers (§9)

**NEVER auto-propagate into Tier 0/1** — `~/.claude/CLAUDE.md`, `~/.claude/rules/`, and `~/.claude/projects/.../memory/` are user-manual-only; `/ce-compound` writes Tier 3 (`docs/solutions/`) exclusively, and the user manually promotes anything worth keeping. This prohibition stays resident; it is not deferred.

For the full 5-tier location/responsibility table and the remaining policy (ce-learnings-researcher's 3+ file gate, Tier 2/3 Korean-prose rule), invoke `Skill(skill="hybrid-workflow-reference")` when deciding where a spec, plan, solution, or memory file belongs.

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
