# Git Workflow

## Commit Message Format

```
<type>: <한국어 설명>

- <변경 이유 또는 맥락 (한국어)>
- <주요 변경 사항 (한국어)>
```

- `<description>`: 한국어로 작성, 명령형 현재형 (예: "로그인 기능 추가", "버그 수정")
- `<optional body>`: 불릿(`-`) 리스트로 작성, 한국어로 작성. WHY와 주요 변경 사항 위주로 기술

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
