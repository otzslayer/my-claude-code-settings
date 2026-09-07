# 3-Tier Boundaries

## ✅ Always (Auto-execute)

Standard engineering hygiene is assumed, not enumerated. Listed here is only what is
specific to this setup. Hard prohibitions live in the Never tier below.

### Toolchain

- Type check with `uv run ty check`. Fall back to `mypy` only when the project pins `[tool.mypy]` in `pyproject.toml` and has no `[tool.ty]`.
- Lint and format with `ruff check` and `ruff format` before declaring Python work done.
- Use `logging`, never `print`.

### Surgical Changes

- Remove imports/variables/functions that YOUR changes made unused
- Match existing code style

### Tool Usage (token-optimized)

- **CodeGraph**: usage is in the MCP server's own `initialize` instructions — don't restate it here. Two things it omits: `codegraph status` (CLI) is the only way to see index health, and the unlisted sub-tools (`node`·`search`·`callers`·`callees`·`impact`·`files`) are reachable in CLI form when you need one in isolation.
- **Search / lookup**: there is **no `Grep`/`Glob` tool** on native macOS/Linux builds — Claude Code 2.1.117 replaced both with embedded `bfs`/`ugrep` reachable through the Bash tool (Windows and npm-installed builds still have them). Search from Bash, for text/regex (CodeGraph doesn't do strings) and for non-code files or paths CodeGraph doesn't index:
  - `grep` and `find` are the default and need no prefix — the shell snapshot shadows them onto **embedded ugrep / bfs**, gitignore-aware (`--ignore-files`) with VCS dirs excluded.
  - `rg` for wide sweeps where output volume is the concern: plain ripgrep, gitignore-aware as well.
  - Explicit `ugrep` (alias `ug`) / `bfs` only for what the shadow can't do: the shadowed `grep` falls back to plain `grep` on `-z`/`-Z`, and the brew build adds lzma·lz4 codecs the embedded one lacks. So `ugrep -z` for archive search, plus fuzzy and boolean patterns.
  - Output too large either way: narrow the pattern or the path first, or cap it with the tool's own flags (`-m`, `--max-count`, `-l` for names only), rather than dumping the whole result.
  - **Always quote glob arguments.** The Bash tool runs zsh, which expands an unquoted `*` before the command ever sees it, and the failure mode differs by whether the pattern happens to match in the cwd: `grep --include=*.ts` dies outright with `no matches found`, while `find . -name *.md` run where `*.md` DOES match silently searches for the wrong names and returns nothing. Write `--include='*.ts'` / `-name '*.md'`, or use ugrep's own file-type flag (`grep -O ts <pattern> .`).
- **Edit**: `Edit`/`Write` are the main path — CodeGraph is read-only.
- **Read tool**: non-code files (`.md`/`.json`/`.toml`/`.yaml`) or areas `codegraph_explore` misses.
- **Never** `cat`/`head`/`tail`/`sed`/`awk`.
- **Subagent dispatch**: the model is fixed at opus. `Agent` tool: `model` only, no `effort` param — effort inherits from the dispatching session. `Workflow` `agent()`: `model` + `effort` both settable per-agent.

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
- Never emit a response without first applying the active output style (`~/.claude/output-styles/*.md`). It governs from the first sentence; rewriting an already-sent response to fix style is not the remedy.

### Surgical Changes

- Never "improve" adjacent code unrelated to task
- Never refactor things that aren't broken
- Never delete pre-existing dead code unless asked
- Never fix unrelated bugs without reporting first

### Memory

- Never auto-write into Tier 0/1 — `~/.claude/CLAUDE.md`, `~/.claude/rules/`, `~/.claude/projects/.../memory/`. These are user-manual-only.
- Learnings and retrospectives belong in `docs/solutions/` (Tier 3); promoting anything from there into Tier 0/1 is the user's manual call.
- Never delete a plan file under `docs/plans/`, including after the work ships. It is a permanent record, not a build artifact.

## Boundary Violation Response

1. Stop immediately
2. Report which boundary was violated
3. Suggest alternatives
4. Wait for approval
