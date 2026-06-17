# Git Workflow

## Commit Message Format

```
<type>: <description in Korean>

- <reason or context for the change (in Korean)>
- <key changes (in Korean)>
```

- `<description>`: Written in Korean, imperative present tense (e.g., "로그인 기능 추가", "버그 수정")
- `<optional body>`: Written as a bullet (`-`) list, in Korean. Focus on the WHY and the key changes.

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

## Branch Naming

```
<type>/<short-description>
```

Examples: `feat/user-auth`, `fix/login-bug`

## PR Workflow

1. Analyze full commit history: `git diff [base-branch]...HEAD`
2. Draft comprehensive PR summary
3. Include test plan
4. Push with `-u` flag if new branch

## Pre-Commit Check

- [ ] Tests passing
- [ ] Lint/format passing
- [ ] Commit message explains "why"
