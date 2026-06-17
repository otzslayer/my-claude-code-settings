# 3-Tier Boundaries

## ✅ Always (Auto-execute)

### Code Quality
- Run tests before committing
- Run linters/formatters
- Run type checker (`uv run ty check`; fall back to `mypy` only when project pins it)
- Add type hints
- Write docstrings for public functions

### Security
- Manage secrets via environment variables
- Validate user input (Pydantic)
- Use parameterized SQL queries
- Exclude sensitive info from error messages

### Patterns
- Follow existing code patterns
- Adhere to project naming conventions
- Add proper error handling
- Use logging (no print statements)

### Surgical Changes
- Remove imports/variables/functions that YOUR changes made unused
- Match existing code style

### Tool Usage (token-optimized)
- **Code intelligence (read)**: CodeGraph MCP — prefer `codegraph_explore` (PRIMARY: an NL question or symbol/file name → the relevant symbols' source per file in one shot, replacing Read). Secondary: `codegraph_search` (name → location only), `codegraph_node` (a single symbol's full source + signature, handles overloads)
- **Code relationships**: CodeGraph `codegraph_callers` (who calls X) / `codegraph_callees` (what X calls) / `codegraph_impact` (blast radius when changing X — required before refactoring). Tracks even the dynamic dispatch that grep can't follow
- **Project layout**: CodeGraph `codegraph_files` (indexed file tree + symbol counts — faster than Glob)
- **Text/regex search**: keep `Grep` — CodeGraph is a symbol graph and does not do string/regex search
- **File/dir lookup**: `Glob` (filename/glob) / `Bash(ls)` (directory listing) — for non-code files or specific paths that `codegraph_files` doesn't capture
- **Code edits**: standard `Edit`/`Write` are the **main path** — CodeGraph is read-only (no edit tools). *Before* editing, assess the blast radius with `codegraph_impact`/`codegraph_callers` ("consult BEFORE editing, not during"). The index is auto-refreshed by the file watcher within ~1s — no manual refresh needed
- **ce-plan research stage**: gather codebase patterns and dependencies automatically with CodeGraph `codegraph_explore`/`codegraph_callers`/`codegraph_impact` (assisting the parallel research agents)
- **ce-work implementation stage**: check the blast radius with `codegraph_impact` before editing → make changes with `Edit`
- **Knowledge graph (broad)**: `/graphify` — broad navigation and architecture overview. Symbol-level queries ("what is X / who calls X / what breaks if I change X") go to CodeGraph
- **Read**: for non-code files (`.md`, `.json`, `.toml`, `.yaml`) or code areas that `codegraph_explore` doesn't capture
- **Never** `cat`/`head`/`tail`/`sed`/`awk`

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
