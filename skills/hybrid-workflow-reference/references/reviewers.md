# 리뷰어 분기 (§5)

리뷰어를 dispatch할 때만 필요하다. 과업 채점·에스컬레이션 근거는 `scoring.md`(§2·§3·§4)에 있다.

quick card가 이미 담고 있는 것: **전 리뷰어 `model=opus` 고정, 세션 모델은 전환 금지.**
이 파일은 그 이유와, Sonnet 재도입 시 되돌릴 분기 기준을 담는다.

## Reviewer branching (§5)

Review is open-ended adversarial reasoning (base 5) — only the highest-stakes judgment escalates. Effort cannot be set per-dispatch (see `scoring.md` → "Applying the score"), so only `model` is pinned. **Do NOT edit the plugin skills to achieve this** — `~/.claude/plugins/...` is machine state, overwritten on plugin update; the resident rules file is the enforcement point and outranks the skills' built-in model tiering. **Currently the split is collapsed — all reviewers run `model=opus`** because sonnet is suspended from routing (`scoring.md` §3 cost inversion); the table below records the intended opus-vs-sonnet split to restore when sonnet is reintroduced.

| Skill | model=opus (adversarial lineage) | model=sonnet (the rest) |
| --- | --- | --- |
| ce-code-review | correctness · security · adversarial | remaining reviewers |
| ce-doc-review | adversarial · security-lens | coherence · feasibility · product-lens · design-lens · scope-guardian |

- `ce-doc-review` runs automatically as ce-plan's mandatory Phase 5.3.8, headless, for every `OUTPUT_FORMAT=md` plan (skipped only for `OUTPUT_FORMAT=html`), inside the same session as `/ce-plan` (no `/clear` boundary to switch models). `ce-code-review` runs in Phase 2'.
- The per-reviewer `model` pin carries the branching regardless. Session model is never switched for review dispatch (avoids a costly cache reload).
