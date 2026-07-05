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
- Prevent XSS; enable CSRF protection
- Verify auth/authz; rate-limit endpoints

### Patterns
- Follow existing code patterns
- Adhere to project naming conventions
- Add proper error handling
- Use logging (no print statements)

### Surgical Changes
- Remove imports/variables/functions that YOUR changes made unused
- Match existing code style

### Tool Usage (token-optimized)
- **Read code**: CodeGraph MCP `codegraph_explore` (PRIMARY — NL question or symbol/file name → relevant source per file in one shot, replaces Read). Also `codegraph_search` (name → location), `codegraph_node` (one symbol's full source + signature).
- **Relationships / impact**: `codegraph_callers` / `codegraph_callees` / `codegraph_impact` (blast radius — **required before refactoring**; catches dynamic dispatch grep misses).
- **Project layout**: `codegraph_files` (indexed tree — faster than Glob).
- **Search / lookup**: `Grep` for text/regex (CodeGraph doesn't do strings); `Glob`·`Bash(ls)` for non-code files or paths `codegraph_files` misses.
- **Edit**: `Edit`/`Write` are the main path (CodeGraph is read-only); assess blast radius with `codegraph_impact`/`codegraph_callers` BEFORE editing, not during. Index auto-refreshes ~1s.
- **Broad navigation / architecture**: `/graphify`; symbol-level queries go to CodeGraph.
- **Read tool**: non-code files (`.md`/`.json`/`.toml`/`.yaml`) or areas `codegraph_explore` misses.
- **Never** `cat`/`head`/`tail`/`sed`/`awk`.
- **Subagent dispatch**: score the subtask's complexity (`~/.claude/rules/hybrid-workflow.md` §3) and set `model` dynamically (opus/fable — sonnet currently suspended from routing, see hybrid-workflow.md §3) accordingly. `Agent` tool: `model` only, no `effort` param — effort inherits from the dispatching session. `Workflow` `agent()`: `model` + `effort` both settable per-agent.

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
