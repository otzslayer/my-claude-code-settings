# 복잡도 채점 · 에스컬레이션 근거 (§2 · §3 · §4)

`~/.claude/rules/hybrid-workflow.md`의 routing quick card가 정본이고, 이 파일은
그 카드가 압축해 버린 *근거*만 담는다. 카드만으로 판정이 서면 이 파일은 읽지 않아도 된다.

리뷰어 dispatch(§5)는 별개 시점이라 `reviewers.md`에 있다.

## Model recalibration (§2)

Formal definition; model notations in CLAUDE.md and elsewhere refer back here.

| Model | Intelligence | Cost burden | Character |
| --- | --- | --- | --- |
| fable-5 | highest | highest (Anthropic list pricing) | sustained multi-subsystem design/implementation, long agentic chains — genuinely long-horizon work only |
| opus-5 | high | moderate-high | complex/open-ended reasoning, architecture, adversarial review — **the current default across every band** |
| sonnet-5 | solid | low list price · **high effective in agentic use** | execution against a finalized artifact (spec/plan) — **currently suspended from routing** (§3 cost inversion) |
| haiku | — | — | **not used** in this pipeline |

- Intelligence: fable > opus > sonnet. **Per-token** cost: sonnet cheapest, fable priciest — but sonnet's **effective** cost inverts above opus on multi-step agentic work (3–4× token/iteration inflation), which is why it is currently out of routing (§3).
- Reserve fable for genuinely complex tasks, not merely long-running ones.

## Complexity scoring — rationale (§3)

The scoring tables themselves live in the resident quick card. What follows is the reasoning the card compresses away.

- **Boundary rounding rule** (concrete instance of §4's "round up at boundaries"): a pure base-5 task (open-ended reasoning, zero additive signals) lands on 5 — round up to opus·high (not opus·medium), so open-ended reasoning always gets high effort.
- **fable-5 gating**: fable is never reached by raw score (the score can't distinguish "many small signals" from "genuinely long-horizon"). Opt in only via an explicit **long-horizon flag** — sustained design/implementation across subsystems, a long agentic chain, or a task exceeding the opus·xhigh ceiling. Default effort `high`, `xhigh` optional.
- **Build-stage carve-out (ce-work / Phase 2')**: build against a finalized plan scores **base 1** (the plan already absorbed the design judgment). Planning-time signals the plan resolved — file count, new module/pattern, public-API/schema change — are **not re-counted** (re-counting double-prices scope the plan already paid for). Default is **opus·medium regardless of file count** — with all bands on opus, the carve-out now caps *effort* at medium (a big plan does not push build to high/xhigh) rather than downgrading the model tier. File count drives unit *volume* — see `units.md` (§6). Build escalates to higher effort only reactively via the §4 re-run gate, never pre-emptively on scope. Whenever a finalized plan exists, this settles the build-vs-"well-defined feature" ambiguity in favor of base 1.
- **Global default**: `model` is Opus 5 (1M context), set via `/model` — it is **not** a `settings.json` key. `effortLevel: high` (resting) is in `~/.claude/settings.json`. `xhigh` is reached per-task within the 8–10 band via the score — never a resting default.
- **Sonnet-5 suspended from routing (cost inversion)**: bands 0–5 use opus·low/medium (not sonnet), and §5's non-adversarial reviewers run opus too. Sonnet's per-token discount is erased by 3–4× token/iteration inflation on this pipeline's agentic work, so its *effective* cost sits at or above opus while accuracy sits below.

  **Evidence — measured against opus-4.8, not opus-5** (kept verbatim; do not relabel to opus-5, nothing here was re-run on it): BrowseComp opus·low $5/67.7% beats sonnet·high $7/64.8%; Artificial Analysis index total opus-4.8 max $3,753 < sonnet-5 max $6,015; a real agentic run, opus-4.8 70 req/$7.07 vs sonnet-5 309 req/$20.95 (see README).

  **Open question since the move to opus-5**: the suspension verdict rests entirely on the 4.8-era figures above. Opus 5's own cost/accuracy ratio has not been measured against sonnet-5 on this pipeline, so the inversion is *assumed to hold*, not verified. Reintroduce sonnet to the low bands (and the §5 non-adversarial reviewers) only when a re-benchmark against opus-5 shows its cost-per-verified-outcome back below opus at that band.

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
