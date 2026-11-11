# Git Workflow

## Commit Message Format

```
<type>: <description in Korean>

- <reason or context for the change (in Korean)>
- <key changes (in Korean)>
```

- `<description>`: Written in Korean as a noun phrase, not a sentence (e.g., "로그인 기능 추가", "버그 수정"). Never end it with "~한다".
- `<optional body>`: Written as a bullet (`-`) list in Korean 개조식. Focus on the WHY and the key changes. See "Korean 개조식" below.

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

## Branch Naming

```
<type>/<short-description>
```

Examples: `feat/user-auth`, `fix/login-bug`

## PR Workflow

1. Analyze full commit history: `git diff [base-branch]...HEAD`
2. Draft comprehensive PR summary. Write the body in Korean 개조식.
3. Include test plan
4. Push with `-u` flag if new branch

## Issues

- Title: a Korean noun phrase.
- Body and comments: Korean 개조식.
- Keep checkboxes, `Part of #n`, `Blocked by:` lines, commit hashes and code identifiers as they are.

## Korean 개조식

Applies to commit bodies, PR bodies, issue bodies and comments.

- An item with a subject (`~이/가`) ends in `~함` or `~음`: `index.html이 트리를 그림`.
- An item without a subject ends in a noun phrase: `fdca0f0 커밋으로 구현`.
- One fact per item. Split into sub-bullets instead of chaining with commas.
- Never join words with a middle dot (`·`): `로그·보조 함수` → `로그 호출과 보조 함수`.
- No word-for-word English idioms: `저장소 뿌리` → `저장소 최상위`.

No linter reads this text, so re-read it against these rules once before committing or posting.
