# `/tag-doc` — 번역 전처리 태깅 커맨드 설계

- 날짜: 2026-06-03
- 상태: 설계 승인됨 (사용자 승인 2026-06-03)
- 유형: 글로벌 유저 커맨드 (`translate-doc`의 전처리 형제)

## 1. 목적

영어 마크다운 원문을 Claude가 인-세션으로 읽어 영어 태그를 생성하고, **원문 frontmatter에 in-place로** 박는다. 이후 `/translate-doc`이 frontmatter를 verbatim 보존하며 번역하므로 한국어 결과물이 태그를 그대로 상속받는다.

핵심 의도(사용자 확인): **원문 → 결과물 태그 상속**. 별도 태깅 단계를 한국어 결과물에 다시 돌릴 필요가 없도록, 번역 전에 원문 한 번으로 끝낸다.

## 2. 파이프라인에서의 위치

```
/tag-doc article.md        # 원문 frontmatter에 tags 추가 (in-place)
    ↓
/translate-doc article.md  # frontmatter verbatim 보존 → article_translated.md (tags 상속)
    ↓
/humanize (수동·선택)       # §8 참조 — 자동 체이닝 안 함
```

세 단계는 사용자가 수동으로 체이닝한다. `/tag-doc`은 standalone이며 `/translate-doc`이 자동 호출하지 않는다.

## 3. 철학 — translate-doc과 동일

- **Claude 인-세션 수행**: 태그 생성은 외부 API 호출 없이 Claude가 직접 한다 (translate-doc이 번역을 직접 하는 것과 동일).
- **DB·Vault 의존 없음**: SQLite·`auto_linker.db`·Vault 스캔 전부 불필요.
- **`obsidian-auto-linker`의 역할**: 코드 호출 대상이 아니라 **태그 생성 규칙의 출처**. 규칙 텍스트를 자산 파일로 이식한다.

## 4. 구조 (translate-doc 대칭)

| 자산 | 경로 | 내용 |
|---|---|---|
| 커맨드 | `~/.claude/commands/tag-doc.md` | 워크플로우 정의 (translate-doc.md 골격 차용) |
| 규칙 자산 | `~/.claude/tag-doc-assets/tag-rules.md` | 이식·적응된 태그 생성 규칙 (§6) |

spec·plan은 translate-doc과 동일하게 글로벌 `~/.claude/docs/`에 둔다.

## 5. 동작 흐름

1. 첫 번째 위치 인자 = 영어 마크다운 경로 (translate-doc과 동일 파싱). 경로 없거나 부재 시 중단·안내.
2. `Read`로 원문 로드. 규칙 자산(`tag-rules.md`) 로드.
3. **title 신호 해석** (§7) — 태그 추출의 최우선 신호.
4. 규칙대로 영어 lowercase-hyphen 태그 생성. **고정 개수 상한 없음** — 문서를 대표하는 엔티티·개념을 빠짐없이 포함하되, 품질 필터(§6)로 잡음·중복을 거른다.
5. frontmatter에 `tags` 병합 (§9).
6. `Edit`로 원문에 **in-place** 기록. JSON·별도 산출 파일 없음.
7. 보고: 추가된 태그 목록, 편집한 파일 경로.

## 6. 태그 생성 규칙 — 이식 = 복사가 아니라 적응

`tag-rules.md`는 `obsidian-auto-linker/src/obsidian_auto_linker/llm/base.py:21-132`의 시스템 프롬프트와 `_filter_generic_tags`(203-279)의 generic 단어 목록을 **이식**하되, `/tag-doc` 맥락에 맞게 적응한다.

### 6.1 이식 시 제거할 것

base.py 프롬프트에는 `/tag-doc`에 맞지 않는 부분이 섞여 있다. 그대로 복사하면 자산 파일이 엉뚱한 지시를 떠안는다.

- **Vault 기존 태그 섹션** (`## Existing Tags in Vault`, Consistency Rule) — v1에서 Vault 일관성 제외했으므로 제거.
- **백링크 섹션** (Backlink Candidates, Backlink Rules) — 제거.
- **출력 포맷 지시** (`"Output valid JSON only"`, `## Response Format {response_format}`) — `/tag-doc`은 JSON이 아니라 frontmatter를 직접 `Edit`하므로 제거. (translate-doc이 시스템 프롬프트의 `<output_format>`를 오버라이드한 것과 동일한 논리.)
- **개수 상한** (`"Limit to top 10~15 most critical tags"`, `max_tags_per_note=30`) — 사용자 지시대로 제거.

### 6.2 이식 후 유지할 것

- **Wikipedia Test**: Wikipedia 문서/기술 문서 제목처럼 구체적 엔티티·알고리즘·아키텍처 이름.
- **제목 우선 신호** (Title as Primary Signal): title에서 핵심 엔티티·개념 먼저 추출.
- **Priority Extraction Rules**: ① title 엔티티 → ② named entities·기법 → ③ 도구·라이브러리 → ④ 핵심 분야.
- **복합어 규칙** (Compound Tag Rules): well-established 용어만 결합, 형용사+명사 결합 금지, named entity 보존.
- **버전 처리**: 버전 특정 시 포함(`pytorch-2.0`), 일반 개념은 버전 제거(`python`).
- **배제 규칙** (Exclusion Rules) 전체: 설명형 접미사 금지(`-guide`·`-overview` 등), adjective-noun 서술 금지, 행위 동사 금지, 질문형 금지, 시간 기반 금지, 무의미 식별자 금지.
- **Good vs Bad 예시 표**.
- **generic 단어 필터**: `note`·`idea`·`work`·`research` 등 + 순수 숫자·hex 컬러·단독 버전 번호 + 길이 2 이하 제거.
- **포맷**: lowercase only, multi-word은 hyphen.

### 6.3 개수 상한 제거에 따른 보강

10-15 상한이 사라진 지금, 태그 폭증을 막는 유일한 방어선은 배제 규칙이다. 사용자의 "대표 단어 다 넣어"와 충돌하지 않는다 — *대표하는* 엔티티를 다 넣자는 것이지 중복·잡음까지 넣자는 게 아니다. 다음을 자산에서 명시적으로 강조한다:

- **No Redundancy**: parent와 close child를 동시에 달지 않음 (`ai-model`+`llm` → `llm`만, `transformer-architecture`+`transformer` → `transformer`만).
- **No adjective-noun 서술**: `efficient-training` → `training`+`optimization` 분리.

즉 "빠짐없이"의 단위는 **개념**이지 표현 변형이 아니다.

## 7. title 신호 출처 (standalone 정의)

auto-linker는 `note.title`(파일명/frontmatter 유래)을 LLM에 먹이지만, `/tag-doc`은 frontmatter title을 일부러 만들지 않는다(§9, carry-through 회피). 따라서 title-first 규칙의 *입력*을 standalone 맥락에서 명시한다:

1. frontmatter에 `title` 필드 있으면 → 그것.
2. 없으면 → **파일명**에서 유도 (auto-linker README도 "파일명에서 생성").
3. 그래도 없으면(파일명이 무의미하면) → 본문 **첫 H1**.

이 해석이 없으면 이식한 "제목 우선" 핵심 규칙이 입력 없이 떠버린다.

## 8. Frontmatter 처리 (auto-linker README 규칙 이식)

- frontmatter 있고 `tags` 있음 → 병합·중복 제거. **기존 태그 우선 순서 보존**, 새 태그를 뒤에 추가.
- frontmatter 있고 `tags` 없음 → `tags` 필드 추가.
- frontmatter 없음 → **`tags`만 든 최소 frontmatter 생성**. `title` 등 다른 필드를 임의 생성하지 않는다.
- **그 외 모든 필드 verbatim 보존**.

`title`을 만들지 않는 이유: translate-doc은 frontmatter title을 verbatim 보존하고 본문 H1이 없으면 번역 H1도 추가하지 않는다. 우리가 영어 title을 만들면 한국어 결과물에 영어 title이 박힌 채 남는다 → 회피.

## 9. 의도적 기본값 (사용자 승인)

1. **in-place 편집** (사본 아님): carry-through 성립을 위해 원문 자체를 수정. 백업 생성 안 함 — git으로 통제.
2. **`auto_tagged: true` 안 붙임**: 최종 노트는 한국어라 나중에 진짜 Vault 도구가 재태깅하는 편이 나을 수 있어 잠그지 않음.
3. **standalone**: translate-doc이 자동 호출하지 않음. 셋은 수동 체이닝.

## 10. v1 범위 제외 (향후 확장)

- **Vault 어휘 일관성** (기존 태그 재사용) — 인-세션 철학 유지 위해 제외. 향후 Vault 태그 목록을 시그널로 먹이는 확장 가능.
- DB·외부 API 호출.
- 백링크.

## 11. `/humanize` 운영 방침 (사용자 질문 답변)

**수동 + 선택적.** translate-doc은 이미 im-not-ai의 번역투 패턴(C-11·A-7·A-15·A-18 등)을 흡수했고 자체검증 패스를 돌리므로 출력이 이미 상당히 de-AI된 상태다. 그 위에 full `/humanize` 5단계를 자동으로 또 돌리면 **과윤문**(im-not-ai 철칙: 변경률 30% 초과 경고, 50% 강제 중단) 위험이 크다.

→ 번역 결과를 눈으로 보고 **아직 AI 티가 남았다고 느낄 때만** `/humanize`를 돌리고 품질 등급을 확인한다. `/tag-doc`·`/translate-doc`과 달리 자동 체이닝하지 않는다.

## 12. 성공 기준

- `/tag-doc <영어.md>` → 원문 frontmatter에 영어 lowercase-hyphen 태그가 품질 규칙에 맞게 들어간다.
- 기존 frontmatter 필드·`tags` 전부 보존·병합된다.
- 이어서 `/translate-doc <영어.md>` 실행 시 한국어 결과물 frontmatter가 동일한 `tags`를 갖는다.
- 외부 API·DB·Vault 접근이 일어나지 않는다.
