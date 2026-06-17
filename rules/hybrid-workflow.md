# Compound + Superpowers Hybrid Workflow

Operating rules that bind Superpowers · Compound Engineering · CodeGraph · graphify · RTK · .remember into a single 7-stage pipeline, in an environment where the Plannotator auto-gate is active.

**Source of truth (spec)**: `~/.claude/docs/superpowers/specs/2026-05-19-compound-superpowers-hybrid-workflow.md`

This document is a summary operating guide for the spec. Stage names, tool names, and trigger conditions must match the spec 1:1. If this document and the spec conflict, the spec wins, and this document is updated to restore alignment.

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
  1. Enter Plan Mode (Shift+Tab)
  2. /ce-plan  [Opus·xhigh]  (parallel research + CodeGraph codegraph_explore/codegraph_callers/codegraph_impact
              + ce-learnings-researcher: query past learnings in docs/solutions/ — only when 3+ files)
              → docs/plans/<draft>.md
  3. ExitPlanMode  (include the ce-plan result path and summary in the plan argument)
  4. plannotator hook fires automatically → browser UI annotation · approval
  5. final save to docs/plans/YYYY-MM-DD-<summary>.md
  6. /clear
       │
       ▼  fresh context, plan file as input  (model switch guidance: → Sonnet high)
Phase 2': Build  ▸ Sonnet · high  (session model fixed — only ce-code-review's reviewer subagents are recommended at Opus xhigh)
  7. superpowers:test-driven-development  [Sonnet·high]  (RED → GREEN → REFACTOR, trivial-case exemption)
  8. /ce-work <plan-path>  [Sonnet·high]  (built-in worktree · parallel safety; before editing, assess blast radius with codegraph_impact, then Edit)
  9. /ce-code-review  [reviewer subagents: Opus·xhigh / session: stays on Sonnet]  (6+ reviewer ensemble — no session model switch)
       │
       ▼
Phase 3: Verify · Learn · Ship  ▸ Sonnet · high
  10. superpowers:verification-before-completion  [Sonnet·high]
       (uv run ty check / ruff check --fix / ruff format / pytest -v)
  11. /ce-compound mode:headless  [Sonnet·high]  (Full, docs/solutions/<problem>.md only)
  12. superpowers:finishing-a-development-branch  [Sonnet·high]  (Korean commit format)
```

---

## Per-stage model policy

The recommended execution model and reasoning effort for each stage. This section is the **formal definition**, and the model notations in CLAUDE.md and the spec refer to it.

### Placement principle

- **Opus · effort `xhigh`** — open-ended reasoning where being wrong is costly. One misstep contaminates every downstream stage.
- **Sonnet · effort `high`** — execution against a finalized artifact (spec/plan). Centered on carrying out, not judging.

### Per-stage table

| Stage / Skill | Model | effort | Rationale |
| --- | --- | --- | --- |
| Phase 1 `superpowers:brainstorming` | Opus | `xhigh` | Grasping intent and surfacing edge cases; if this is wrong, everything is off |
| Phase 2 `/ce-plan` | Opus | `xhigh` | Architectural decisions, tradeoffs, synthesizing research |
| Phase 2' `superpowers:test-driven-development` | Sonnet | `high` | Writing tests based on the plan, execution-centered |
| Phase 2' `/ce-work` | Sonnet | `high` | Executing the finalized plan |
| Phase 2' `/ce-code-review` | Opus (reviewer) | `xhigh` | Opus recommended **at the reviewer subagent level**. Session stays on Sonnet (no in-session switch — see mechanism below). Not enforced |
| Phase 3 `superpowers:verification-before-completion` | Sonnet | `high` | Running commands and verifying, mechanical |
| Phase 3 `/ce-compound mode:headless` | Sonnet | `high` | Structured learning documentation (headless) |
| Phase 3 `superpowers:finishing-a-development-branch` | Sonnet | `high` | Commit · push · PR |
| `superpowers:systematic-debugging` (bug) | Opus | `xhigh` | Root-cause tracing, open-ended reasoning |
| Exemption cases (type/linter/rename/trivial) | Sonnet | `high` | Simple work, low judgment weight |

### Switch mechanism (manual guidance at boundaries)

> **Constraint**: The main agent **cannot switch its own model mid-session.** Model·effort switches are only possible via the user's `/model`·`/effort` input or in a new session after `/clear`.

Operating contract:

- At the start of each stage (especially a new session after `/clear`), the model **announces that stage's recommended model·effort to the user** and, if it differs from the current setting, **guides the switch before** proceeding. It does not enforce — announce and confirm only. (Since the model can't always query its own effort, "announce + guide" is safer than "inspect".)
- The pipeline's `/clear` points are the natural switch boundaries. Phases 1 and 2 are continuous on Opus xhigh, so there's no switch between them. At the Phase 2→2' boundary, step down to Sonnet high.
- **ce-code-review exception**: the ce-code-review inside Phase 2' is not a `/clear` boundary. Therefore it **does not change the session model** — the session stays on Sonnet high (an in-session `/model` switch reloads the entire history cache, which is costly, making the most expensive stage even more expensive). ce-code-review fans out to 6+ reviewer **subagents**, so "Opus xhigh" refers to the **reviewer level**, not the session. Raising reviewers to Opus is in the subagent-model-specification domain (separate from the global 'manual guidance at boundaries'; we do not adopt plugin frontmatter pins), and is not enforced. If cost is the priority, let reviewers inherit the session model (Sonnet), and run reviewers on Opus only for changes where quality matters especially.

Current global default (`~/.claude/settings.json`): `model: Opus`, `effortLevel: xhigh`. Therefore:

| Entering stage | Switch command to announce |
| --- | --- |
| Opus xhigh stages (brainstorming, ce-plan, debugging) | (same as default — no switch needed) |
| ce-code-review (inside Phase 2') | (no session switch — session stays on Sonnet, only reviewer subagents recommended at Opus. See "ce-code-review exception" above) |
| Sonnet high stages (build·verify·compound·ship·exemption) | `/model sonnet` and `/effort high` |
| Returning from a Sonnet stage to an Opus stage | `/model opus` and `/effort xhigh` |

Note: Sonnet 4.6 does not support `xhigh` and its default effort is already `high`. Since the global default is `xhigh`, when switching to Sonnet also guide `/effort high` to make the intent explicit.

---

## 95% confidence opener (Phase 1 first turn — model utterance)

The form of the first question the model poses to the user when entering the brainstorming skill (identical to spec §4.1):

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

For non-product work (large refactors · broad documentation · tooling), do not apply this — there's no 'real user need' to press on, so a product-style probe spins idle. This lays ce-brainstorm's Product Pressure Test on top of the 95% opener _without swapping tools_ (the brainstorming tool stays superpowers; only the questioning methodology is absorbed from ce-brainstorm — rationale in the spec §3 table).

---

## Triggers

### Full pipeline activation (same as the Plan Mode trigger)

Any one of the following:

- 3+ file changes
- New module · pattern · architectural decision
- New dependency added
- public API or data schema change
- Explicit user request (e.g., "design this properly", "make a plan")

### Exemption (skip Phases 1·2, go straight to Phase 2' — TDD also exempt) ▸ Sonnet · high

- Adding type annotations only
- ruff auto-fixes
- Single-file rename (no behavior change)
- Comment/docstring cleanup
- Bumping dependency versions only
- Obvious refactors of one to a few dozen lines (existing tests pass as-is)

Handle exemption cases on **Sonnet · high** (if you entered on the global default Opus xhigh, guide `/model sonnet`·`/effort high`). Even when applying an exemption, run `pytest` once after the change. If the exemption call is ambiguous, confirm via `AskUserQuestion`.

### Partial activation

- Broad README update → Phase 1 [Opus·xhigh] + Phase 3 [Sonnet·high] (no build stage)
- eval result analysis/regression → only Phase 3's `/ce-compound` [Sonnet·high] (artifacts/\*.csv as input)

---

## Memory · documentation 4-tier

| Tier | Location | Responsibility | Who changes it |
| --- | --- | --- | --- |
| 0. Global behavior rules | `~/.claude/CLAUDE.md`, `~/.claude/rules/` | Collaboration principles, gating | **User manual only** |
| 1. Global meta-memory | `~/.claude/projects/.../memory/`, `~/.claude/.remember/` | user/feedback/project/reference, per-session | Model auto-updates only for user/feedback utterances |
| 2. Project decisions | `<proj>/docs/superpowers/specs/`, `<proj>/docs/plans/` | spec, plan | Model authors, user approval gate |
| 3. Project learning accumulation | `<proj>/docs/solutions/` | ce-compound output (**file content written in Korean**, frontmatter keys·enum values stay English) (write) + ce-learnings-researcher query (read) | Model auto (headless) |
| 4. Project visualization | `<proj>/graphify-out/`, `<proj>/docs/solutions/*.graph.md` | graphify output | User or model on invocation |
| 5. Project progress tracking | `<proj>/TODO.md` | Follow-up work list | Both |

**Policy**:

- No automatic `/ce-compound` propagation into Tier 0/1. If a Tier 3 solution is judged valuable, the user manually moves it into Tier 0/1.
- Tier 3 is not write-only. In Phase 2's `/ce-plan` research stage, `ce-learnings-researcher` queries docs/solutions/ and reflects past learnings into the plan → the compound learning loop closes.
- ce-learnings-researcher invocation gate: fires only when `docs/solutions/` has **3+ files**. Below that, search noise overwhelms signal, so skip it.

---

## Errors / edge cases

| Situation | Policy |
| --- | --- |
| ce-plan's Write blocked inside Plan Mode | Approach 2 (PostToolUse hook) fallback. Record the result in spec §9 Open Questions, then update the spec |
| plannotator fails to intercept ExitPlanMode | Manually invoke `/plannotator-annotate docs/plans/<file>` |
| ce-work parallel subagent worktree conflict | ce-work's built-in policy (abort → retry serially) |
| ce-compound headless misclassification | docs/solutions/ is git tracked; user manually corrects·deletes |
| ce-compound token overflow | Pass only summary·headers as input, leverage RTK compression |
| docs/solutions/ is empty or has 2 or fewer files | Skip ce-learnings-researcher invocation — querying in a low-signal state risks injecting noise into the plan |
| TDD exemption call ambiguous | Confirm with the user via `AskUserQuestion` |

---

## Spec synchronization on change

When updating this document, also update the spec (`docs/superpowers/specs/2026-05-19-compound-superpowers-hybrid-workflow.md`) to maintain 1:1 alignment. If stage names, tool names, or trigger conditions differ between the two documents, correct this document against the spec.
