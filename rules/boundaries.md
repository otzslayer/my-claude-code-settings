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

### Tool Usage

- **Search**: native macOS/Linux builds ship no `Grep`/`Glob` tool — search from Bash. The shell snapshot shadows `grep`/`find` onto ugrep/bfs (gitignore-aware, VCS dirs excluded); reach for `rg` on wide sweeps where output volume is the concern.
- **Always quote glob arguments.** The Bash tool runs zsh, which expands an unquoted `*` before the command ever sees it. `grep --include=*.ts` dies with `no matches found`, while `find . -name *.md` run where `*.md` matches in the cwd silently searches for the wrong names and returns nothing. Write `-name '*.md'` / `--include='*.ts'`.

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
