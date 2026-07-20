# Compound + Superpowers Hybrid Workflow

Operating rules binding Superpowers · Compound Engineering · CodeGraph · graphify · RTK · .remember into a single 7-stage pipeline, under an active Plannotator auto-gate. This document is the single source of truth for the pipeline — no separate spec to sync.

---

## 7-Stage Pipeline (§1, compressed)

Stage **structure** (phases, `/clear` boundaries) is fixed. Model·effort is not fixed per stage — each task is scored (see §3) and routed to a band.

```
Phase 1: Spec  (model·effort via complexity scoring — §3)
  superpowers:brainstorming  (95% confidence opener at the start)
  (optional) graphify
  → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
  → user review · approval
       │
       ▼  /clear
Phase 2: Plan  (when the Plan Mode trigger is met)
  1. non-plan-mode: /ce-plan  (parallel research + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: query docs/solutions/ — only when 3+ files)
              → docs/plans/<draft>.md
  2. ce-doc-review  (AUTOMATIC as ce-plan's Phase 5.3.8, headless, md-only; reviewer branching — §5)
  3. plannotator annotate docs/plans/<file> — review the canonical plan in place
     (blocks until the browser returns approved/dismissed/annotated; no ExitPlanMode bracket, no ~/.claude/plans/ copy)
  4. approved → stop, do NOT implement inline; annotated → address in non-plan-mode on the same file, re-run until approved; dismissed → not an approval, do not proceed
  5. /clear
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

**Phase 2 note (§1 — Plan Mode ↔ plannotator decoupling)**:

- ce-plan core work (plan-file `Write`, ce-doc-review autofix) runs in **non-plan-mode** — Plan Mode blocks both.
- The plannotator human gate runs on the canonical file afterward: `plannotator annotate docs/plans/<file>`, blocking until the browser returns `approved`/`dismissed`/`annotated`; only `approved` proceeds to `/clear`. Order enforced: mechanical AI review (ce-doc-review) → forced human review (plannotator). No `ExitPlanMode` bracket and no `~/.claude/plans/` copy — the annotated artifact **is** the canonical `docs/plans/` file, so ce-doc-review's autofixes cannot be overwritten by re-pasted plan text.
- The enforcement shifts from a hook-level tool-deny to the annotate command's block-until-decision plus the skill loop (address `annotated` → re-run until `approved`). Both paths block progression until a browser decision; the annotate path additionally keeps a single source of truth. The general Plan Mode `ExitPlanMode` path (with its `PermissionRequest` plannotator gate and `~/.claude/plans/` promotion) still serves non-ce-plan work.
- **Gate salience reinforced by a hook** (`~/.claude/settings.json`): a `PostToolUse` `Write|Edit` hook on `docs/plans/*.md` re-injects the plannotator-gate reminder every time the plan file is written — draft at Phase 5.2, then deepening and ce-doc-review autofix Edits at 5.3/5.3.8, all in the main session (ce-doc-review is skill-invoked in-session; only its reviewer personas are subagents). So the reminder lands right before the Phase 5.4 handoff menu instead of decaying from the start-of-ce-plan injection over the long run — countering ce-plan's own 5.4 menu (Publish/Open/ce-work) that omits the gate. A paired `PreToolUse` `Write|Edit` hook injects the Korean-prose requirement at the same plan-write moment (see §9).
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

Under 1-hour caching, cache **writes cost 2× base input** (reads stay 0.1×), and every subagent spawn re-establishes its full prefix (CLAUDE.md + skill injection + unit packet) as a fresh 2× write. **Spawn count — not per-token price — is the dominant reducible cost.** Two defaults, one per stage:

- **Coarse units (Phase 2, `/ce-plan`)** — group cohesive Implementation Units (shared files, types, dependency chains) into fewer, larger U-IDs. Fewer units = fewer spawns = fewer 2× prefix writes. The primary lever, and it lives in the plan. Do not fragment a cohesive change into fine-grained units just to look granular.
- **Serial subagents (Phase 2', `/ce-work`)** — prefer serial execution over parallel fan-out unless wall-clock speed is explicitly the priority. Parallelism's only gain is latency; for cost it adds merge/contention/integration overhead (ce-work caps parallel batches at 3–5 workers for this reason). Serial keeps both subagent benefits — clean per-unit rollback and a lean orchestrator context — without the parallel-batch tax.

**Trade-off accepted**: gives up wall-clock speed and cross-unit visibility (separate workers can't see each other's emerging patterns; ce-work's "Simplify as You Go" pass partly mitigates). For a tightly-coupled cluster where cross-unit consolidation beats clean rollback, run that cluster inline in the main context with a `/clear` at the stage boundary — choose per cluster, not globally. Inline vs subagent is roughly a token wash; the real win is fewer spawns from coarser units, which applies to both modes.

---

## 95% confidence opener (§7 — Phase 1 first turn, model utterance)

First question the model poses when entering the brainstorming skill:

> "지금 만들려는 것에 대해 1-2문장으로 설명해 주세요. 저는 95% 확신이 생길 때까지 질문을 던지겠습니다 — 표면적으로 원하는 것이 아니라 진짜로 필요한 것을 짚기 위해서입니다. 가정과 엣지 케이스를 도전하겠습니다."

Operating contract:

- Repeat brainstorming checklist item 3 (clarifying questions) until 95% confidence.
- One question at a time. Do not accept the user's first answer uncritically.
- Actively surface unstated edge cases (failure modes, missing data, permissions, concurrency, etc.).
- Do not move to design-presentation below 95%.

**rigor-probe lens (product-facing work — absorbed from ce-brainstorm)**: for work with a user/value surface (new feature · endpoint · behavior change), derive questions through 5 lenses:

- **evidence** — actual behavior (time·cost·workaround), not just a stated want
- **specificity** — the concrete beneficiary and what changes for them
- **counterfactual** — how it's done today, and what changes if it's not built
- **attachment** — the minimal form delivering the same value
- **durability** — whether the assumption holds against near-term change

For non-product work (large refactors · broad documentation · tooling), skip this — there is no 'real user need' to press on, so a product-style probe spins idle.

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

| Tier | Location | Responsibility | Who changes it |
| --- | --- | --- | --- |
| 0. Global behavior rules | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | Collaboration principles, gating | **User manual only** |
| 1. Global meta-memory | `~/.claude/projects/.../memory/`, `~/.claude/.remember/` | user/feedback/project/reference, per-session | Model auto-updates only for user/feedback utterances |
| 2. Project decisions | `<proj>/docs/superpowers/specs/`, `<proj>/docs/plans/` | spec, plan (**plan body prose in Korean**, code·identifiers·file paths·frontmatter keys·enum values stay English) | Model authors, user approval gate |
| 3. Project learning accumulation | `<proj>/docs/solutions/` | ce-compound output (**content in Korean**, frontmatter keys·enum values stay English) write + ce-learnings-researcher query read | Model auto (headless) |
| 4. Project visualization | `<proj>/graphify-out/`, `<proj>/docs/solutions/*.graph.md` | graphify output | User or model on invocation |

**Policy**:

- No automatic `/ce-compound` propagation into Tier 0/1. The user manually promotes a valuable Tier 3 solution.
- Tier 3 is not write-only: in Phase 2's `/ce-plan` research, `ce-learnings-researcher` queries docs/solutions/ and reflects past learnings into the plan — closing the compound learning loop.
- ce-learnings-researcher invocation gate: fires only when `docs/solutions/` has **3+ files**. Below that, noise overwhelms signal — skip it.
- Tier 2 plan language: the `docs/plans/` body is Korean prose (identifiers, code, file paths, frontmatter keys/enum values stay English), mirroring Tier 3. Enforced at plan-write time by the `PreToolUse` `Write|Edit` hook (§1 Phase 2 note) — the global "respond in Korean" rule never reached it because a written file artifact is not a chat response.

---

## Errors / edge cases (§10)

| Situation | Policy |
| --- | --- |
| plannotator human gate (normal path) | `plannotator annotate docs/plans/<file>` after ce-doc-review (§1 Phase 2 note) — blocks until the browser returns `approved`/`dismissed`/`annotated`; only `approved` proceeds to `/clear` |
| annotate returns `annotated` | address feedback in non-plan-mode on the same file, re-run `plannotator annotate docs/plans/<file>` until `approved` |
| annotate returns `dismissed` (closed without approving) | not an approval — do not `/clear` or start `/ce-work`; re-run annotate or confirm intent with the user |
| ce-work parallel subagent worktree conflict | ce-work's built-in policy (abort → retry serially) |
| ce-compound headless misclassification | docs/solutions/ is git tracked; user manually corrects·deletes |
| ce-compound token overflow | Pass only summary·headers as input, leverage RTK compression |
| docs/solutions/ empty or ≤2 files | Skip ce-learnings-researcher — querying in a low-signal state injects noise into the plan |
| TDD exemption call ambiguous | Confirm via `AskUserQuestion` |
