# Compound + Superpowers Hybrid Workflow

Operating rules that bind Superpowers · Compound Engineering · CodeGraph · graphify · RTK · .remember into a single 7-stage pipeline, in an environment where the Plannotator auto-gate is active.

This document is the single source of truth for the pipeline. There is no separate spec to keep in sync.

---

## 7-Stage Pipeline (compressed)

The `[model·effort]` next to each stage is the recommended execution model. For the formal definition and switch mechanism, see the "Per-stage model policy" section below.

```
Phase 1: Spec  ▸ Opus · xhigh
  superpowers:brainstorming  [Opus·xhigh]  (95% confidence opener at the start)
  (optional) graphify
  → docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md
  → user review · approval
       │
       ▼  /clear  (next stage is also Opus xhigh — no switch needed)
Phase 2: Plan  ▸ Opus · xhigh  (when the Plan Mode trigger is met)
  1. Enter Plan Mode (Shift+Tab, or the agent's EnterPlanMode tool — ce-plan runs only inside Plan Mode, the plannotator gate precondition)
  2. /ce-plan  [Opus·xhigh]  (parallel research + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: query past learnings in docs/solutions/ — only when 3+ files)
              → docs/plans/<draft>.md
  2a. ce-doc-review  (runs AUTOMATICALLY as ce-plan's Phase 5.3.8, headless, md-only; reviewers pinned to Sonnet — see override below)
  3. ExitPlanMode  (include the ce-plan result path and summary in the plan argument)
  4. plannotator hook fires automatically → browser UI annotation · approval
  5. final save to docs/plans/YYYY-MM-DD-<summary>.md
  6. /clear
       │
       ▼  fresh context, plan file as input  (model switch guidance: → Sonnet medium)
Phase 2': Build  ▸ Sonnet · medium  (single session effort across Phase 2'–3; ce-code-review reviewers pinned to Sonnet)
  7. superpowers:test-driven-development  [Sonnet·medium]  (RED → GREEN → REFACTOR, trivial-case exemption)
  8. /ce-work <plan-path>  [Sonnet·medium]  (built-in worktree · parallel safety; before editing, assess blast radius with codegraph_impact, then Edit)
  9. /ce-code-review  [reviewers forced to Sonnet / session stays Sonnet medium]  (6+ reviewer ensemble — no session model switch)
       │
       ▼
Phase 3: Verify · Learn · Ship  ▸ Sonnet · medium
  10. superpowers:verification-before-completion  [Sonnet·medium]
       (uv run ty check / ruff check --fix / ruff format / pytest -v)
  11. /ce-compound mode:headless  [Sonnet·medium]  (Full, docs/solutions/<problem>.md only)
  12. superpowers:finishing-a-development-branch  [Sonnet·medium]  (Korean commit format)
```

---

## Per-stage model policy

The recommended execution model and reasoning effort for each stage. This section is the **formal definition**, and the model notations in CLAUDE.md refer to it.

### Placement principle

- **Opus · effort `xhigh`** — open-ended reasoning where being wrong is costly. One misstep contaminates every downstream stage.
- **Sonnet · effort `medium`** — execution against a finalized artifact (spec/plan). Centered on carrying out, not judging.

### Per-stage table

| Stage / Skill | Model | effort | Rationale |
| --- | --- | --- | --- |
| Phase 1 `superpowers:brainstorming` | Opus | `xhigh` | Grasping intent and surfacing edge cases; if this is wrong, everything is off |
| Phase 2 `/ce-plan` | Opus | `xhigh` | Architectural decisions, tradeoffs, synthesizing research |
| Phase 2 `ce-doc-review` (auto, headless) | Sonnet (reviewers) | inherit | Runs inside the Opus ce-plan session; reviewers pinned to `model=sonnet` (see override below). Session effort ignored |
| Phase 2' `superpowers:test-driven-development` | Sonnet | `medium` | Writing tests based on the plan, execution-centered |
| Phase 2' `/ce-work` | Sonnet | `medium` | Executing the finalized plan |
| Phase 2' `/ce-code-review` | Sonnet (reviewers) | inherit | Reviewers pinned to `model=sonnet`; session stays Sonnet medium (no in-session switch). Session effort ignored |
| Phase 3 `superpowers:verification-before-completion` | Sonnet | `medium` | Running commands and verifying, mechanical |
| Phase 3 `/ce-compound mode:headless` | Sonnet | `medium` | Structured learning documentation (headless) |
| Phase 3 `superpowers:finishing-a-development-branch` | Sonnet | `medium` | Commit · push · PR |
| `superpowers:systematic-debugging` (bug) | Opus | `xhigh` | Root-cause tracing, open-ended reasoning |
| Exemption cases (type/linter/rename/trivial) | Sonnet | `medium` | Simple work, low judgment weight |

### Switch mechanism (manual guidance at boundaries)

> **Constraint**: The main agent **cannot switch its own model mid-session.** Model·effort switches are only possible via the user's `/model`·`/effort` input or in a new session after `/clear`.

> **Plan Mode is the exception**: unlike model·effort switches, Plan Mode entry **can** be agent-triggered via the `EnterPlanMode` tool (a user-approval gate is attached). ce-plan runs only inside Plan Mode and is the precondition for the plannotator gate, so **before invoking ce-plan, if not already in Plan Mode, call `EnterPlanMode` first**. The `workflow-stage-inject.sh` `*ce-plan` hook re-asserts this only when ce-plan is invoked via the Skill tool; a user-typed `/ce-plan` may bypass it, so this instruction — not the hook — is the guarantee.

Operating contract:

- At the start of each stage (especially a new session after `/clear`), **announce that stage's recommended model·effort** and, if it differs from the current setting, **guide the switch before** proceeding — announce and confirm, never enforce.
- The pipeline's `/clear` points are the natural switch boundaries. Phases 1 and 2 are continuous on Opus xhigh; at the Phase 2→2' boundary, step down to Sonnet medium.
- **Review-subagent override**: ce-doc-review · ce-code-review pin every reviewer to `model=sonnet` at dispatch; no session `/model` switch. See "Review-subagent model override" below.

Current global default (`~/.claude/settings.json`): `model: Opus`, `effortLevel: xhigh`. Therefore:

| Entering stage | Switch command to announce |
| --- | --- |
| Opus xhigh stages (brainstorming, ce-plan, debugging) | (same as default — no switch needed) |
| ce-doc-review (auto, inside the Opus ce-plan session) | (no session switch — reviewers pinned to Sonnet at dispatch. See "Review-subagent model override" below) |
| ce-code-review (inside Phase 2') | (no session switch — session stays Sonnet medium, reviewers pinned to Sonnet at dispatch. See "Review-subagent model override" below) |
| Sonnet medium stages (build·verify·compound·ship·exemption) | `/model sonnet` and `/effort medium` |
| Returning from a Sonnet stage to an Opus stage | `/model opus` and `/effort xhigh` |

Note: Since the global default is `xhigh`, when switching to Sonnet also guide `/effort medium` to make the intent explicit.

### Review-subagent model override

`ce-doc-review` and `ce-code-review` both dispatch reviewer subagents. Force every reviewer to run on **Sonnet**, regardless of the parent session model.

**Mechanism.** The `Agent` dispatch primitive exposes a `model` parameter but no `effort` parameter — so a reviewer's *model* is pinnable per-dispatch, its *effort* is not. Per the decision to **ignore session effort**, do not manage reviewer effort: just pin `model=sonnet` at dispatch and let effort fall where it may. Do NOT edit the plugin skills to achieve this — `~/.claude/plugins/...` is machine state, overwritten on plugin update. This document is the enforcement point; it outranks the skills' built-in model tiering.

**ce-doc-review** is not opt-in — it runs automatically as `ce-plan`'s mandatory Phase 5.3.8, headless, for every `OUTPUT_FORMAT=md` plan (skipped only for `OUTPUT_FORMAT=html`). It runs *inside* the Opus `xhigh` ce-plan session, so there is no `/clear` boundary to switch models. Its built-in tiering would otherwise send `feasibility`/`product`/`adversarial` to the parent (Opus), `design`/`security`/`scope` to Sonnet, and `coherence` to the cheapest tier (Haiku). **Override: dispatch every ce-doc-review reviewer — including the automatic headless pass — with `model=sonnet`.** This drops the 3 parent-tier reviewers off Opus.

**ce-code-review** runs in Phase 2' (Sonnet medium session). Its built-in tiering already puts every reviewer on Sonnet when the session is Sonnet (`correctness`/`security`/`adversarial` inherit the session; the rest use Sonnet mid-tier). **Override: dispatch every reviewer with `model=sonnet` anyway, so "Sonnet" holds unconditionally even if the session is not Sonnet.** No session `/model` switch.

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

### Exemption (skip Phases 1·2, go straight to Phase 2' — TDD also exempt) ▸ Sonnet · medium

- Adding type annotations only
- ruff auto-fixes
- Single-file rename (no behavior change)
- Comment/docstring cleanup
- Bumping dependency versions only
- Obvious refactors of one to a few dozen lines (existing tests pass as-is)

Handle exemption cases on **Sonnet · medium** (if you entered on the global default Opus xhigh, guide `/model sonnet`·`/effort medium`). Even when applying an exemption, run `pytest` once after the change. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

### Partial activation

- Broad README update → Phase 1 [Opus·xhigh] + Phase 3 [Sonnet·medium] (no build stage)
- eval result analysis/regression → only Phase 3's `/ce-compound` [Sonnet·medium] (artifacts/\*.csv as input)

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
| ce-plan's Write blocked inside Plan Mode | Approach 2 (PostToolUse hook) fallback |
| plannotator fails to intercept ExitPlanMode | Manually invoke `/plannotator-annotate docs/plans/<file>` |
| ce-work parallel subagent worktree conflict | ce-work's built-in policy (abort → retry serially) |
| ce-compound headless misclassification | docs/solutions/ is git tracked; user manually corrects·deletes |
| ce-compound token overflow | Pass only summary·headers as input, leverage RTK compression |
| docs/solutions/ is empty or has 2 or fewer files | Skip ce-learnings-researcher invocation — querying in a low-signal state risks injecting noise into the plan |
| TDD exemption call ambiguous | Confirm with the user via `AskUserQuestion` |
