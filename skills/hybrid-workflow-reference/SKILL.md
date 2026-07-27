---
name: hybrid-workflow-reference
description: Deferred reference sections of the Compound + Superpowers hybrid workflow — §6 unit granularity and serial-vs-parallel execution strategy for ce-plan/ce-work, §7 the 95% confidence brainstorming opener and rigor-probe lenses, §9 the memory and documentation tier table. Use when grouping Implementation Units or choosing serial vs parallel subagents in ce-plan/ce-work, when opening a superpowers:brainstorming session, or when deciding which tier a spec, plan, solution, or memory file belongs to. The always-resident rules/hybrid-workflow.md holds §1-§5, §8, §10.
---

# Hybrid workflow — deferred reference (§6 · §7 · §9)

These sections were split out of `~/.claude/rules/hybrid-workflow.md` because they
are consulted at specific decision points rather than every turn. That file remains
the source of truth for the pipeline; this one holds the three stage-scoped sections
verbatim. Section numbering is unchanged.

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

