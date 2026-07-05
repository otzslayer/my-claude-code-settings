---
description: Find public-domain historical images for a note and record them into its Pixel Banner frontmatter in place
argument-hint: <input_file>
allowed-tools: Read, Write, Edit, Bash, WebSearch, WebFetch, AskUserQuestion
---

# banner-doc

Obsidian 노트를 읽어 그 글에 어울리는 **공개 도메인(PD) 역사 이미지**(고판화·고지도·빈티지
도표·고전 회화) 후보 2~3개를 찾아 제시하고, 사용자가 고르면 그 **원격 이미지 URL + 출처 메타**를
노트의 Pixel Banner 프론트매터에 **제자리 기록**한다.

`/tag-doc`·`/translate-doc`과 같은 전역 커맨드 계열이지만 결정적 차이가 있다: 이들은 **세션 내
완결·외부 API 없음**이었던 반면, `/banner-doc`은 **웹 검색·이미지 조회(외부 네트워크 접근)를
동반하는 에이전트형 커맨드**다. 또한 이 커맨드는 Obsidian **Pixel Banner 플러그인의 "URL 이미지
허용" 설정이 켜져 있음을 전제**한다 — 프론트매터의 `banner` URL로 노트 상단 배너를 렌더하는 것이
그 플러그인이다. 이 커맨드는 설정을 바꾸지 않고 전제만 상기한다.

## Arguments

User input: `$ARGUMENTS`

Parse:
- First positional arg = **input file path** (required).

입력 파일이 제공되지 않거나 경로가 존재하지 않으면 **중단하고 무엇이 빠졌는지** 알린다.

## Assets

- 검색·감별 SSOT: `~/.claude/banner-doc-assets/search-and-vetting.md`

## Workflow

### Step 1 — 로드 & 주제 신호
1. `Read` 입력 노트.
2. `Read` 자산(`~/.claude/banner-doc-assets/search-and-vetting.md`)하고 모든 섹션을 내재화한다.
3. **주제 신호 해석 순서**: 프론트매터 `title` → 파일명(확장자 제거·구분자→공백) → 본문 첫 H1(`# `).
4. 노트가 한국어일 수 있으므로, 검색용 **영어/라틴어 개념어**로 변환한다(자산 § 컨셉 도출 참조).

### Step 2 — 비주얼 컨셉 2~3갈래
자산 § 컨셉 도출에 따라 **최소 1개 직결형 + 1~2개 연상형** 컨셉을 만든다. 후보 묶음에 둘이
섞이도록. 각 컨셉마다 영어/라틴어 검색어 세트(작가·유파·매체·시대)를 준비한다.

### Step 3 — 검색
1. **1차 소스 = Wikimedia Commons** (자산 § Wikimedia 완전 배선):
   - **`Bash` curl + `-H 'User-Agent: …'` 로 API JSON을 발행한다. `WebFetch` 사용 금지**
     (헤더·raw JSON 불가 → 403·파싱 실패).
   - `generator=search`, `gsrnamespace=6`, `iiprop=url|extmetadata|mime|size`, `iiurlwidth=1200`.
   - 배너 값은 **`thumburl` 우선, 없으면 `url` 폴백**.
2. **보조 소스 best-effort** (자산 § 보조 소스): Met·Rijksmuseum·NYPL·Internet Archive 등을
   `WebSearch`/`WebFetch`로 탐색하되 **직접 래스터 URL을 안정 추출 가능할 때만** 보강; 못 뽑으면
   스킵.

### Step 4 — 감별
자산 § 감별 휴리스틱 순서대로: **R7 라이선스 필터(PD/CC0/자유만) → R8 mime 필터(image/* 만,
SVG·PDF·GIF 배제) → R9 시각 판정**(썸네일 curl → 스크래치패드 임시 저장 → `Read`로 실제 확인,
볼트엔 저장 안 함).

**최소 2개 확보 실패 시** 임의 저품질 후보로 채우지 말고 사용자에게 **검색어 조정을 요청하고
중단**한다.

### Step 5 — 제시 & 선택 (`AskUserQuestion`)
1. **멱등성 처리**: 입력 노트에 이미 `banner` 필드가 있으면, 제시 전에 **현재 배너 URL을 먼저
   알리고** 선택지에 **"현재 배너 유지"**를 넣는다.
2. `AskUserQuestion`으로 최종 후보를 제시. 각 옵션:
   - `label`: 작가·소재 짧은 제목.
   - `description`: **이미지 URL** + 원제·작가·연도·라이선스·이 글에 맞는 이유 한 줄.
3. **옵션 상한 = 4개** (형제 `translate-doc.md`와 동일 제약). 후보 + 메타 옵션 총합이 4를 넘지
   않게 후보 수를 캡한다:
   - `banner` 필드 **없음** → 후보 최대 **3개** + "다 별로 → 재검색" = 4.
   - `banner` 필드 **있음** → 후보 최대 **2개** + "현재 배너 유지" + "다 별로 → 재검색" = 4.
4. 항상 **"다 별로 → 재검색"** 옵션 포함.
5. 선택 분기:
   - **"현재 배너 유지"** → 아무것도 바꾸지 않고 종료.
   - **"재검색"** → Step 2로 돌아가 컨셉·검색어 조정.
   - **후보 선택** → Step 6.

### Step 6 — 적용 (제자리)
선택 후보를 프론트매터의 `banner`·`banner_source`·`banner_license`·`banner_title`·
`banner_creator`·`banner_year` 6필드에 기록한다.

- `extmetadata.Artist`의 HTML(`<bdi><a>…</a></bdi>`)을 **제거해 평문화**한 뒤 `banner_creator`에.
- **소스 파생 값은 신뢰하지 않는다** — 6개 `banner*` 스칼라 전부(URL 포함)를 **인용/이스케이프된
  YAML 문자열**로 기록하고(내부 `"`·`\` 이스케이프), **개행·제어문자를 제거**한다. HTML 제거는
  평문을 만들 뿐 YAML 구조 메타문자(`:`·선두 `-`·`#`·`|`·`"`)를 남기므로 이스케이프 없이
  기록하면 프론트매터 손상·외부 키 주입 위험.
- 프론트매터 **3-케이스**:
  - **프론트매터 있고 `banner*` 있음** → 기존 `banner*`를 **덮어씀**(비-banner 필드 보존).
  - **프론트매터 있고 `banner*` 없음** → `banner*`만 **추가**(나머지 필드·순서·값 보존).
  - **프론트매터 없음** → `banner*`만 담은 **최소 블록** 생성(`title` 등 **날조 금지**).
- **본문은 바이트 단위 보존.** `banner*` 외 어떤 것도 건드리지 않는다.
- `Edit`(병합) 또는 `Write`(신규 블록 생성)로 **입력 파일 자체**를 수정한다. 사본·백업 안 만듦.

### Step 7 — 리포트
간결 블록 하나만 출력한다. **문서 본문은 출력하지 않는다.**

```
✓ Banner → <input_path>
  · 주제 신호: <frontmatter|filename|body-h1>
  · 선택: <원제> / <작가> / <연도>
  · 라이선스: <license>
  · 출처: <source_url>
  · banner 필드: <created|overwritten|added>
  · 전제: Pixel Banner "URL 이미지 허용" 설정 필요
```

## Hard rules
- **라이선스**: 소스가 PD/CC0/자유로 태깅한 필드만 신뢰한다. **스킬은 저작권을 독자 판단하지 않고
  소스의 태깅을 신뢰한다** — 법적 판단은 스킬의 책임 범위 밖이다.
- **직접 URL만**: `mime`이 `image/*`(jpg·png·webp)인 직접 래스터 URL만. SVG·PDF·GIF 배제.
- **원격 참조 전용**: 볼트에 이미지를 다운로드하지 않는다. 시각 감별용 임시 저장은 스크래치패드
  (볼트 밖)에만 하고 사용 후 정리한다.
- **제자리 편집**: 입력 파일을 in-place 수정한다. `_banner` 사본·백업을 만들지 않는다(git이 소스
  관리).
- **본문 불변**: 본문은 바이트 단위 보존. `banner*` 6필드만 쓴다. `title` 등 다른 필드 날조 금지.
- **네트워크 규약**: Wikimedia API JSON 호출은 **`Bash` curl + `-H 'User-Agent: …'` 헤더 필수**
  (`WebFetch` 금지 — 헤더·raw JSON 불가). 인증 토큰을 쿼리에 넣지 않는다.
- **쓰기 안전**: 소스 파생 값은 신뢰 불가 → 노트에 기록 전 **YAML 인용/이스케이프·개행/제어문자
  제거**. HTML 제거만으로는 YAML 구조 메타문자가 남는다.
- **최소 2개 미확보 시 중단**: 임의 저품질 후보로 채우지 않는다.
- **멱등성/재실행이 정상 흐름**: 기존 `banner`가 있으면 현재 URL을 알리고 "현재 배너 유지" 옵션을
  제공한다. 재실행 시 `banner*`만 덮어쓰고 비-banner 필드는 보존한다.
