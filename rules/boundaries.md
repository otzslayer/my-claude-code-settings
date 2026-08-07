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

- **Read code · relationships · architecture**: CodeGraph MCP `codegraph_explore` — the single tool on the MCP surface, and the first call for any of these. ONE call returns the verbatim line-numbered source grouped by file (Read-equivalent — do NOT re-Read what it showed), the call paths among those symbols, and an always-on **blast radius** section. Query takes an NL question or a bag of symbol/file names. The other tools (`node`·`search`·`callers`·`callees`·`impact`·`files`) are unlisted by default because `explore` already folds their answers in; reach for their CLI form (`codegraph node/query/callers/impact/...`) only when you need one in isolation. `codegraph status` (CLI) is the exception — index health is the one thing `explore` does not report.
- **Before refactoring**: `codegraph_explore` on the symbols you are about to change. Its blast-radius section is always on, so the primary call already tells you who depends on them and which lack covering tests. No separate impact call needed.
- **Search / lookup**: there is **no `Grep`/`Glob` tool** on native macOS/Linux builds — Claude Code 2.1.117 replaced both with embedded `bfs`/`ugrep` reachable through the Bash tool (Windows and npm-installed builds still have them). Search from Bash, for text/regex (CodeGraph doesn't do strings) and for non-code files or paths CodeGraph doesn't index:
  - `grep` and `find` are the default and need no prefix — the shell snapshot shadows them onto **embedded ugrep / bfs**, gitignore-aware (`--ignore-files`) with VCS dirs excluded. RTK is configured NOT to rewrite them (`exclude_commands` in rtk's `config.toml`), because `rtk grep` runs BSD `grep` in a subprocess and would lose that gitignore awareness — a results change, not just a formatting one.
  - `rg` for wide sweeps where output volume is the concern: RTK still rewrites it to `rtk rg`, which compresses while staying gitignore-aware. **Don't type the `rtk` prefix yourself.**
  - Explicit `ugrep` (alias `ug`) / `bfs` only for what the shadow can't do: the shadowed `grep` falls back to plain `grep` on `-z`/`-Z`, and the brew build adds lzma·lz4 codecs the embedded one lacks. So `ugrep -z` for archive search, plus fuzzy and boolean patterns.
  - Output too large either way: pipe through `ugrep ... | rtk pipe -f grep` or `bfs ... | rtk pipe -f find`. Caps at ~10 lines per file with a visible `+N` marker — lossy but not silent.
  - **Always quote glob arguments.** The Bash tool runs zsh, which expands an unquoted `*` before the command ever sees it, and the failure mode differs by whether the pattern happens to match in the cwd: `grep --include=*.ts` dies outright with `no matches found`, while `find . -name *.md` run where `*.md` DOES match silently searches for the wrong names and returns nothing. Write `--include='*.ts'` / `-name '*.md'`, or use ugrep's own file-type flag (`grep -O ts <pattern> .`).
- **Edit**: `Edit`/`Write` are the main path (CodeGraph is read-only); run `codegraph_explore` on the target symbols BEFORE editing, not during. Index auto-refreshes ~1s.
- **Read tool**: non-code files (`.md`/`.json`/`.toml`/`.yaml`) or areas `codegraph_explore` misses. In `~/.claude` itself that is nearly everything — the index holds ~6 files (this repo is markdown and shell), so here `grep` is the tool and CodeGraph has nothing to say.
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
