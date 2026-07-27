# 유닛 분량 · 실행 전략 (§6)

`/ce-plan`에서 Implementation Unit(U-ID)을 묶을 때, `/ce-work`에서 직렬·병렬을
고를 때만 필요하다.

## Unit granularity & execution strategy (§6 — token discipline under 1-hour caching)

Under 1-hour caching, cache **writes cost 2× base input** (reads stay 0.1×), and every subagent spawn re-establishes its full prefix (CLAUDE.md + skill injection + unit packet) as a fresh 2× write. **Spawn count — not per-token price — is the dominant reducible cost.** Two defaults, one per stage:

- **Coarse units (Phase 2, `/ce-plan`)** — group cohesive Implementation Units (shared files, types, dependency chains) into fewer, larger U-IDs. Fewer units = fewer spawns = fewer 2× prefix writes. The primary lever, and it lives in the plan. Do not fragment a cohesive change into fine-grained units just to look granular.
- **Serial subagents (Phase 2', `/ce-work`)** — prefer serial execution over parallel fan-out unless wall-clock speed is explicitly the priority. Parallelism's only gain is latency; for cost it adds merge/contention/integration overhead (ce-work caps parallel batches at 3–5 workers for this reason). Serial keeps both subagent benefits — clean per-unit rollback and a lean orchestrator context — without the parallel-batch tax.

**Trade-off accepted**: gives up wall-clock speed and cross-unit visibility (separate workers can't see each other's emerging patterns; ce-work's "Simplify as You Go" pass partly mitigates). For a tightly-coupled cluster where cross-unit consolidation beats clean rollback, run that cluster inline in the main context with a `/clear` at the stage boundary — choose per cluster, not globally. Inline vs subagent is roughly a token wash; the real win is fewer spawns from coarser units, which applies to both modes.
