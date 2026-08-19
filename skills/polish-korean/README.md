# polish-korean

이미 쓴 한국어 산문을 한 패스에 교정하는 Claude Code 스킬입니다. 문장 부호, 번역투, 비유, 형식명사, 완곡 표현이 어긋난 곳을 찾아 고치고 무엇을 왜 고쳤는지 보고합니다.

내용은 건드리지 않습니다. 문체와 표현만 손봅니다.

## 설치

폴더를 통째로 스킬 디렉터리 아래에 두세요.

```bash
git clone <repo> /tmp/polish-korean
cp -r /tmp/polish-korean ~/.claude/skills/polish-korean
```

프로젝트 안에서만 쓰려면 `~/.claude/skills/` 대신 `.claude/skills/`에 넣으면 됩니다.

규칙이 전부 `references/` 안에 있어서 바깥 파일에 기대지 않습니다. 폴더를 복사하면 그대로 돕니다.

## 사용법

```
/polish-korean docs/plans/2026-08-19-refactor.md
```

파일 경로를 주면 파일 모드로 동작합니다. `--output`을 생략하면 입력 파일을 제자리에서 덮어쓰고 원본 사본은 세션 scratchpad 디렉터리에 남습니다. 사본 경로는 보고 끝에 나옵니다.

```
/polish-korean docs/draft.md --output docs/draft.polished.md
```

`--output`을 주면 원본을 두고 그 경로에 결과를 씁니다.

```
/polish-korean 이 문서는 사용자에 대한 이해를 바탕으로 작성되어졌다.
```

파일 경로가 아닌 인자는 텍스트로 봅니다. 결과를 응답으로 돌려줍니다.

교정이 끝나면 두 가지를 보고합니다. 고친 곳은 근거 규칙과 `before → after` 발췌를 붙여 전부 싣습니다. 규칙에는 걸리지만 문맥상 두기로 한 곳은 왜 두었는지 따로 적습니다. 두 번째 목록에서 그 판단을 검토하시면 됩니다.

## 규칙 두 갈래

`references/house-style.md`가 하우스 스타일입니다. 문장 부호, 쉼표, 종결, 목록, 번역투, 비유 금지, 리듬, 정확도 우선을 규정합니다. 이 파일이 스킬의 취향을 결정합니다. 자기 문체에 맞게 고쳐 쓰라고 둔 파일입니다.

`references/ai-tell-rules.md`가 AI 티 규칙입니다. AI가 쓴 한국어에 남는 패턴을 `A-15`, `D-4` 같은 ID로 묶어 두었습니다. 번역투, 영어 병기, 구조, 관용구, 격식, 수식, 완곡, 접속, 형식명사까지 아홉 묶음입니다.

둘이 부딪히면 하우스 스타일이 이깁니다.

## 자기 문체에 맞추기

`references/house-style.md`를 고치면 됩니다. 이 스킬이 판단의 기준으로 삼는 유일한 취향 파일입니다.

이 저장소의 사본은 Claude Code output style `~/.claude/output-styles/korean.md`를 그대로 복사한 파일입니다. 같은 방식으로 쓰시려면 자기 output style을 복사해 넣으세요.

```bash
cp ~/.claude/output-styles/korean.md ~/.claude/skills/polish-korean/references/house-style.md
```

원본을 고칠 때마다 다시 복사해야 합니다. 자동 동기화는 없습니다.

`references/ai-tell-rules.md`는 [im-not-ai](https://github.com/epoko77-ai/im-not-ai) 플러그인의 AI 티 패턴 목록에서 하우스 스타일이 이미 덮는 항목을 빼고 추렸습니다. ID는 그쪽 체계를 따릅니다. 항목을 더하거나 빼도 스킬은 문제없이 실행됩니다.

## 손대지 않는 것

- 프런트매터, 코드 블록, 인라인 코드
- 인용 블록. 남의 글일 수 있습니다
- 링크 URL, 파일 경로, 명령어, 플래그, 식별자
- 고유명사, 제품명, 모델명, 수치, 날짜, 단위
- 문서의 경어 등급. 해요체로 쓴 글은 해요체로 둡니다. 한 문서 안에서 등급이 섞였을 때만 우세한 쪽으로 통일합니다

교정 전에 문장별로 내용 앵커를 잡습니다. 원문의 주장을 이루는 핵심 명사와 개념어입니다. 앵커가 사라질 것 같은 교정은 그 문장째 되돌립니다. 문체를 다듬다 뜻이 바뀌는 일을 이렇게 막습니다.

## 언제 다른 도구를 쓰나

이 스킬은 사람이 쓴 글을 다듬으라고 만들었습니다. 손댈 곳이 너무 많아 문서 전체를 다시 쓰는 수준이면 그 사실을 알리고 멈춥니다. 중증 AI 초안은 [im-not-ai](https://github.com/epoko77-ai/im-not-ai)의 `/humanize-korean --strict`가 맡습니다.

맞춤법과 오탈자만 고치실 거면 스킬 없이 그냥 부탁하시는 편이 빠릅니다.
