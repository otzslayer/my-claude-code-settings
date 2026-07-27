# 메모리 · 문서 tier (§9)

spec · plan · solution · memory 파일을 **어디에 둘지** 정할 때만 필요하다.

"Tier 0/1 자동 반영 금지" 금지 규칙은 지연 로드하지 않는다 —
`~/.claude/rules/hybrid-workflow.md` §9에 상주한다.

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
