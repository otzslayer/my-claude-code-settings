# Compound + Superpowers Hybrid Workflow

Operating rules that bind Superpowers · Compound Engineering · CodeGraph · graphify · RTK · .remember into a single 7-stage pipeline, in an environment where the Plannotator auto-gate is active.

This document is the single source of truth for the pipeline. There is no separate spec to keep in sync.

---

## 7-Stage Pipeline (compressed)

Model·effort is no longer fixed per stage. Each task is scored for complexity and routed to a model·effort band — see "Complexity scoring" below. The stage **structure** (phases, `/clear` boundaries) stays fixed; only the model-assignment mechanism changed.

```
Phase 1: Spec  (model·effort via complexity scoring — see below)
  superpowers:brainstorming  (95% confidence opener at the start)
  (optional) graphify
  → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
  → user review · approval
       │
       ▼  /clear
Phase 2: Plan  (when the Plan Mode trigger is met)
  1. non-plan-mode: /ce-plan  (parallel research + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: query past learnings in docs/solutions/ — only when 3+ files)
              → docs/plans/<draft>.md
  2. ce-doc-review  (runs AUTOMATICALLY as ce-plan's Phase 5.3.8, headless, md-only; reviewer model branching — see "Reviewer branching" below)
  3. EnterPlanMode → immediately ExitPlanMode, edit-free bracket (finalized plan as argument) — re-triggers the plannotator hard gate
  4. plannotator hook fires automatically → browser UI annotation · approval (blocks `/clear` until approved)
     (if annotations request changes: edit the plan in non-plan-mode, then repeat step 3's bracket to re-trigger the gate)
  5. /clear
       │
       ▼  fresh context, plan file as input
Phase 2': Build  (single session across Phase 2'–3; ce-code-review reviewer model branching — see below)
  6. superpowers:test-driven-development  (RED → GREEN → REFACTOR, trivial-case exemption)
  7. /ce-work <plan-path>  (built-in worktree · parallel safety; before editing, assess blast radius with codegraph_impact, then Edit)
  8. /ce-code-review  (reviewer model branching, no session model switch — see below)
       │
       ▼
Phase 3: Verify · Learn · Ship
  9. superpowers:verification-before-completion
       (uv run ty check / ruff check --fix / ruff format / pytest -v)
  10. /ce-compound mode:headless  (Full, docs/solutions/<problem>.md only)
  11. superpowers:finishing-a-development-branch  (Korean commit format)
```

**Phase 2 note (§9 — Plan Mode ↔ plannotator decoupling)**: ce-plan's core work (plan-file `Write`, ce-doc-review autofix) runs in **non-plan-mode**, because Plan Mode blocks both. The plannotator `ExitPlanMode` hard gate (browser approval required before `/clear`) is re-triggered afterward via an edit-free `EnterPlanMode → ExitPlanMode` bracket — mechanical AI review (ce-doc-review) lands before forced human review (plannotator), and the hard gate survives the move to non-plan-mode. The general "Plan Mode before complex work" discipline (see CLAUDE.md) still applies elsewhere; this is a narrow carve-out for ce-plan's own execution.

---

## Model recalibration (§2)

This section is the **formal definition**; the model notations in CLAUDE.md and elsewhere refer back to it.

| Model | Intelligence | Cost burden | Character |
| --- | --- | --- | --- |
| fable-5 | highest | highest (Anthropic list pricing) | sustained multi-subsystem design/implementation, long agentic chains — genuinely long-horizon work only |
| opus-4.8 | high | moderate-high | complex/open-ended reasoning, architecture, adversarial review |
| sonnet-5 | solid | low | execution against a finalized artifact (spec/plan) |
| haiku | — | — | **not used** in this pipeline |

Intelligence ordering: fable > opus > sonnet. Cost ordering: fable is the most expensive tier — reserve it for tasks that are genuinely complex, not merely long-running.

## Complexity scoring (§3)

Every task — main-session work at a `/clear` boundary, and each subagent dispatch — is scored 0–10 and routed to a model·effort band. Score = **base** (cognitive character) **+ additive signals** (scope), capped at 10.

### Base score (cognitive character)

| Character | Base |
| --- | --- |
| Mechanical / execution (build, verify, rename, typing, formatting) | 1 |
| Standard implementation (well-defined feature, bounded bug) | 3 |
| Open-ended reasoning (design, brainstorming, root-cause debugging) | 5 |

### Additive signals (apply once each, when present)

| Signal | Add |
| --- | --- |
| File count: 2 files +1 · 3–5 files +2 · 6+ files +3 (apply only the single tier matching the actual count, not cumulatively) | +1 to +3 |
| New module / pattern / architectural decision | +2 |
| New dependency | +1 |
| Public API or data schema change | +2 |
| Cross-cutting concern (concurrency, security, migration) | +2 |
| Substantive ambiguity (requirements branch multiple ways) | +2 |

### Band → model · effort (score-routing ceiling = opus · xhigh)

| Score | Band | Model | Effort |
| --- | --- | --- | --- |
| 0–2 | Trivial / mechanical | sonnet-5 | low |
| 3–5 | Standard | sonnet-5 | medium |
| 6–7 | Moderately hard | opus-4.8 | high |
| 8–10 | Complex | opus-4.8 | xhigh |

**Boundary rounding rule** (the concrete instance of §4's "round up at boundaries" below): a pure base-5 task (open-ended reasoning, zero additive signals) lands exactly on 5 — round up to opus·high, so open-ended reasoning never stays on sonnet.

**fable-5 gating**: fable is never reached by raw score — the cumulative score can't distinguish "many small signals" from "a genuinely long-horizon task," and fable's real edge is the latter. fable is opted into only by an explicit **long-horizon flag**: sustained design/implementation spanning multiple subsystems, a long agentic chain, or a task judged to exceed the opus·xhigh ceiling. Default effort `high` when fable is used, `xhigh` optional.

Current global default (`~/.claude/settings.json`): `model: opus[1m]`, `effortLevel: high` (resting). `xhigh` is reached per-task within the 8–10 band via the score — it is not a resting default.

## Escalation policy (§4)

- **Round up at boundaries (insurance premium)**: if the scoring itself is genuinely ambiguous between two adjacent bands (e.g., unsure whether an additive signal applies, or a base score like pure open-ended reasoning lands exactly on a band's own top value with no signals to push it further — see the §3 boundary rounding rule), or the task has large blast radius / is hard to reverse, break ties by rounding up one band. This is a tie-breaker for genuine uncertainty, not a rule to re-round every score that happens to sit at a band's numeric ceiling — a clean 7 (already routed to opus·high) is not rounded again into 8–10.
- **Re-run gate — narrow, objective-signal-first**: only re-score/re-run at a higher band when a deterministic signal fires — test/typecheck/verification failure, **or** scope discovered mid-task (file count, cross-cutting concerns) exceeds the initial band's assumption — **and** the task is hard to reverse at the same time. The scope-overrun trigger exists so work with no test signal (prose, governance edits) and mid-investigation scope growth aren't structurally excluded from the gate. Self-reported confidence is a secondary signal only, for areas with no objective signal (design, research).

### Applying the score

The main agent **cannot switch its own model mid-session** — model·effort changes only via the user's `/model`·`/effort` input or a new session after `/clear`. That constraint shapes how the score is applied at each dispatch point:

| Dispatch point | Mechanism |
| --- | --- |
| Main session (after scoring, at a `/clear` boundary or new task) | Announce both `/model` and `/effort` and guide the switch — announce and confirm, never enforce |
| `Agent`-tool subagent (reviewers, ce-work workers) | `model` is pinned at dispatch; the `Agent` tool exposes no `effort` parameter, so effort is **inherited from the dispatching session** |
| `Workflow` `agent()` — available to the top-level/orchestrating session only, not to a subagent it dispatches | Both `model` and `effort` are set per-agent — fully dynamic |

This mechanism boundary means the "opus·high" reviewer notation in "Reviewer branching" below is realized as `model=opus` pin + session-inherited effort, not a pinned effort. Once the parent session rests at `effortLevel: high` (per §2 above), Agent-tool opus reviewers land near `high` via inheritance — if the parent session is `xhigh`, the reviewer inherits `xhigh` instead.

## Reviewer branching (§5)

Review is inherently open-ended adversarial reasoning (base 5) — only the highest-stakes judgment escalates. Effort cannot be set per-dispatch (see "Applying the score" above), so only `model` is pinned. Do NOT edit the plugin skills to achieve this — `~/.claude/plugins/...` is machine state, overwritten on plugin update; this document is the enforcement point and outranks the skills' built-in model tiering.

| Skill | model=opus (adversarial lineage) | model=sonnet (the rest) |
| --- | --- | --- |
| ce-code-review | correctness · security · adversarial | remaining reviewers |
| ce-doc-review | adversarial · security-lens | coherence · feasibility · product-lens · design-lens · scope-guardian |

`ce-doc-review` runs automatically as `ce-plan`'s mandatory Phase 5.3.8, headless, for every `OUTPUT_FORMAT=md` plan (skipped only for `OUTPUT_FORMAT=html`) — it runs inside the same session as `/ce-plan`, so there is no `/clear` boundary to switch models; the `model=opus`/`model=sonnet` split above is enforced at dispatch regardless. `ce-code-review` runs in Phase 2'. Session model is never switched for review dispatch (avoids a costly cache reload) — the per-reviewer `model` pin is what carries the branching.

---

## Unit granularity & execution strategy (token discipline under 1-hour caching)

Under 1-hour prompt caching, cache **writes cost 2× base input** (reads stay 0.1×), and every subagent spawn re-establishes its full prefix (CLAUDE.md + skill injection + unit packet) as a fresh 2× write. Spawn count — not per-token price — is the dominant reducible cost. Two defaults follow, one per stage:

- **Coarse units (Phase 2, `/ce-plan`)** — group cohesive Implementation Units (shared files, types, or dependency chains) into fewer, larger U-IDs. Fewer units = fewer spawns = fewer 2× prefix writes. This is the primary lever and it lives in the plan, not in execution. Do not fragment a cohesive change into many fine-grained units just to make the plan look granular.
- **Serial subagents (Phase 2', `/ce-work`)** — prefer serial subagent execution over parallel fan-out unless wall-clock speed is explicitly the priority. Parallelism's only gain is latency; when optimizing cost it adds merge/contention/integration overhead (ce-work already caps parallel batches at 3-5 workers for exactly this reason). Serial keeps both subagent benefits — clean per-unit rollback and a lean orchestrator context — without the parallel-batch tax.

**Trade-off accepted**: this gives up wall-clock speed and cross-unit visibility (separate workers can't see each other's emerging patterns; ce-work's "Simplify as You Go" pass partly mitigates). For a tightly-coupled cluster where cross-unit consolidation matters more than clean rollback, run that cluster inline in the main context with a `/clear` at the stage boundary instead — choose per cluster, not globally. Inline vs subagent is roughly a wash on tokens; the real win is the reduced spawn count from coarser units, which applies to both execution modes.

---

## 95% confidence opener (Phase 1 first turn — model utterance)

The form of the first question the model poses to the user when entering the brainstorming skill:

> "지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95% 확신이 생길 때까지 질문을 던지겠습니다 — 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다."

Operating contract:

- Repeat brainstorming checklist item 3 (clarifying questions) until 95% confidence.
- Keep the one-question-at-a-time principle. Do not accept the user's first answer uncritically.
- Actively surface unstated edge cases (failure modes, missing data, permissions, concurrency, etc.).
- Do not move to the design-presentation stage below 95%.

**rigor-probe lens (for product-facing work — absorbed from ce-brainstorm)**:

So the 95% opener doesn't scatter in any direction, for work with a user/value surface (new feature · endpoint · behavior change), derive questions through the following 5 lenses:

- **evidence** — is there actual behavior (time·cost·workaround), not just a stated want
- **specificity** — who is the concrete beneficiary and what changes for them
- **counterfactual** — how is it done today, and what changes if it's not built
- **attachment** — what is the minimal form that delivers the same value
- **durability** — does this assumption hold against near-term change

For non-product work (large refactors · broad documentation · tooling), do not apply this — there's no 'real user need' to press on, so a product-style probe spins idle.

---

## Triggers

### Full pipeline activation (same as the Plan Mode trigger)

Any one of the following:

- 3+ file changes
- New module · pattern · architectural decision
- New dependency added
- public API or data schema change
- Explicit user request (e.g., "design this properly", "make a plan")

### Exemption (skip Phases 1·2, go straight to Phase 2' — TDD also exempt)

- Adding type annotations only
- ruff auto-fixes
- Single-file rename (no behavior change)
- Comment/docstring cleanup
- Bumping dependency versions only
- Obvious refactors of one to a few dozen lines (existing tests pass as-is)

These typically land in the 0–2 band (mechanical base, no additive signals) per §3; guide the switch if the current session differs. Even when applying an exemption, run `pytest` once after the change. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

### Partial activation

- Broad README update → Phase 1 + Phase 3 (no build stage; score each phase's task per §3)
- eval result analysis/regression → only Phase 3's `/ce-compound` (artifacts/\*.csv as input; typically scores low per §3)

---

## Memory · documentation tiers

| Tier | Location | Responsibility | Who changes it |
| --- | --- | --- | --- |
| 0. Global behavior rules | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | Collaboration principles, gating | **User manual only** |
| 1. Global meta-memory | `~/.claude/projects/.../memory/`, `~/.claude/.remember/` | user/feedback/project/reference, per-session | Model auto-updates only for user/feedback utterances |
| 2. Project decisions | `<proj>/docs/superpowers/specs/`, `<proj>/docs/plans/` | spec, plan | Model authors, user approval gate |
| 3. Project learning accumulation | `<proj>/docs/solutions/` | ce-compound output (**file content written in Korean**, frontmatter keys·enum values stay English) (write) + ce-learnings-researcher query (read) | Model auto (headless) |
| 4. Project visualization | `<proj>/graphify-out/`, `<proj>/docs/solutions/*.graph.md` | graphify output | User or model on invocation |

**Policy**:

- No automatic `/ce-compound` propagation into Tier 0/1. If a Tier 3 solution is judged valuable, the user manually moves it into Tier 0/1.
- Tier 3 is not write-only. In Phase 2's `/ce-plan` research stage, `ce-learnings-researcher` queries docs/solutions/ and reflects past learnings into the plan → the compound learning loop closes.
- ce-learnings-researcher invocation gate: fires only when `docs/solutions/` has **3+ files**. Below that, search noise overwhelms signal, so skip it.

---

## Errors / edge cases

| Situation | Policy |
| --- | --- |
| plannotator hard gate (normal path) | Re-triggered via the edit-free `EnterPlanMode → ExitPlanMode` bracket after ce-doc-review (§9) — the `PermissionRequest` hook on `ExitPlanMode` blocks `/clear` until browser approval |
| plannotator bracket fails to fire / gets bypassed | Manually invoke `/plannotator-annotate docs/plans/<file>` |
| ce-work parallel subagent worktree conflict | ce-work's built-in policy (abort → retry serially) |
| ce-compound headless misclassification | docs/solutions/ is git tracked; user manually corrects·deletes |
| ce-compound token overflow | Pass only summary·headers as input, leverage RTK compression |
| docs/solutions/ is empty or has 2 or fewer files | Skip ce-learnings-researcher invocation — querying in a low-signal state risks injecting noise into the plan |
| TDD exemption call ambiguous | Confirm with the user via `AskUserQuestion` |
