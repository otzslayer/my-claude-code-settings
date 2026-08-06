# 3-Tier Boundaries

## ✅ Always (Auto-execute)

Standard engineering hygiene is assumed, not enumerated. Listed here is only what is
specific to this setup. Hard prohibitions live in the Never tier below.

### Toolchain

- Type check with `uv run ty check`. Fall back to `mypy` only when the project pins `[tool.mypy]` in `pyproject.toml` and has no `[tool.ty]`.
- Use `logging`, never `print`.

### Surgical Changes

- Remove imports/variables/functions that YOUR changes made unused
- Match existing code style

### Tool Usage (token-optimized)

- **Read code**: CodeGraph MCP `codegraph_explore` (PRIMARY — NL question or symbol/file name → relevant source per file in one shot, replaces Read). Also `codegraph_search` (name → location), `codegraph_node` (one symbol's full source + signature).
- **Relationships / impact**: `codegraph_callers` / `codegraph_callees` / `codegraph_impact` (blast radius — **required before refactoring**; catches dynamic dispatch grep misses).
- **Project layout**: `codegraph_files` (indexed tree — cheaper than shelling out to `find`/`ls -R`).
- **Search / lookup**: there is **no `Grep`/`Glob` tool** on this setup — native macOS/Linux builds dropped both as of Claude Code 2.1.117, folding search into the Bash tool. Search from Bash instead, for text/regex (CodeGraph doesn't do strings) and `Bash(ls ...)`/`Bash(find ...)` for non-code files or paths `codegraph_files` misses:
  - `grep`/`rg` are the default. RTK rewrites `grep` -> `rtk grep` automatically for output compression; **don't type the `rtk` prefix yourself.**
  - `ugrep` (alias `ug`) and `bfs` are base dependencies installed by `scripts/install.sh` and work in the sandbox — reach for `ugrep` when you need archive/compressed search (`-z`), fuzzy matching, or boolean patterns, and `bfs` as a faster breadth-first `find`. **Trade-off:** RTK does **not** rewrite `ugrep`/`ug`/`bfs`, so their raw output reaches context uncompressed. Prefer plain `grep` for wide sweeps that could dump a lot of lines; use `ugrep`/`bfs` when their capability is the point.
- **Edit**: `Edit`/`Write` are the main path (CodeGraph is read-only); assess blast radius with `codegraph_impact`/`codegraph_callers` BEFORE editing, not during. Index auto-refreshes ~1s.
- **Broad navigation / architecture**: CodeGraph `codegraph_explore` with a natural-language question.
- **Read tool**: non-code files (`.md`/`.json`/`.toml`/`.yaml`) or areas `codegraph_explore` misses.
- **Never** `cat`/`head`/`tail`/`sed`/`awk`.
- **Subagent dispatch**: the model is fixed at opus; score the subtask's complexity against the routing quick card in `~/.claude/rules/hybrid-workflow.md` to set effort. `Agent` tool: `model` only, no `effort` param — effort inherits from the dispatching session. `Workflow` `agent()`: `model` + `effort` both settable per-agent.

## ⚠️ Ask First (Require Approval)

### Structural

- Database schema changes
- Adding new dependencies
- Modifying existing API interfaces
- Reorganizing file/folder structure

### Configuration

- CI/CD configuration modifications
- Environment configuration file changes
- Build script modifications
- Docker configuration changes

### Deletion

- Removing existing features
- Replacing libraries
- Removing legacy code
- Deleting test cases

### External

- Adding external API integrations
- New service dependencies
- Infrastructure change proposals

## 🚫 Never (Strictly Forbidden)

### Security

- Never commit secrets/API keys
- Never hardcode passwords
- Never bypass security validation
- Never log sensitive data

### Code Quality

- Never use `--no-verify`
- Never delete/disable failing tests
- Never commit non-compiling code
- Never modify `node_modules/`, `vendor/`, `.venv/`

### Process

- Never change production config without approval
- Never make assumptions without verification
- Never repeat same approach after 3 failed attempts
- Never proceed while ignoring errors

### Surgical Changes

- Never "improve" adjacent code unrelated to task
- Never refactor things that aren't broken
- Never delete pre-existing dead code unless asked
- Never fix unrelated bugs without reporting first

## Boundary Violation Response

1. Stop immediately
2. Report which boundary was violated
3. Suggest alternatives
4. Wait for approval
