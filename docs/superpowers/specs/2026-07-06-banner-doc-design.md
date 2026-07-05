---
title: /banner-doc — Pixel Banner용 공개 도메인 역사 이미지 배너 커맨드 설계
date: 2026-07-06
status: approved
related:
  - 2026-06-03-tag-doc-design.md
  - 2026-05-29-translate-doc-translationese-harvest-design.md
---

# /banner-doc 설계

## 1. 개념 (한 줄)

Obsidian 노트를 읽고, 그 글에 어울리는 **공개 도메인 역사적 이미지**(고판화·고지도·빈티지 도표·고전 회화 — fergusfinn.com 커버 감성)를 여러 저장소에서 찾아 **후보 2~3개를 제시**하고, 사용자가 고르면 그 **원격 이미지 URL + 출처 메타**를 노트의 Pixel Banner 프론트매터에 **제자리 기록**하는 전역 슬래시 커맨드.

## 2. 위치 · 계보

- **커맨드 파일**: `~/.claude/commands/banner-doc.md` (전역, `/tag-doc`·`/translate-doc`과 동일 계열)
- **에셋(선택)**: 검색 소스 우선순위·개념 도출 휴리스틱이 길어지면 `~/.claude/banner-doc-assets/` 로 분리 (tag-doc의 `tag-doc-assets/tag-rules.md` 선례). 초판은 커맨드 본문에 인라인 가능하면 인라인.
- `/tag-doc`이 "세션 내 완결, 외부 API 없음"이었던 것과 달리, `/banner-doc`은 **웹 검색·이미지 조회를 동반하는 에이전트형 커맨드**다. 이 차이를 커맨드 문서 상단에 명시한다.

## 3. 인자

- `$ARGUMENTS` 첫 번째 위치 인자 = **입력 파일 경로**(필수). `/tag-doc`과 동일 규약.
- 파일이 없거나 경로가 존재하지 않으면 중단하고 무엇이 빠졌는지 알린다.
- `allowed-tools`: `Read, Write, Edit, Bash, WebSearch, WebFetch, AskUserQuestion` (+ 선택적으로 Artifact — §7 대안 참고).

## 4. 파이프라인

### Step 1 — 로드 & 주제 신호 해석
1. 입력 파일 `Read`.
2. 주제 신호 해석 순서: 프론트매터 `title` → 파일명(확장자 제거·구분자→공백) → 본문 첫 H1(`# `). tag-doc의 title-signal 규약 재사용.
3. 본문을 훑어 글의 **주제·시대·개념·정서**를 요약. 노트는 한국어일 가능성이 높으므로, 검색용 **영어/라틴어 개념어**로 변환한다.

### Step 2 — 비주얼 컨셉 도출 (직결 + 연상 혼합)
- 후보 방향을 2~3갈래로 생성한다. **최소 1개 직결형**(주제어 직접 매칭) + **1~2개 연상형**(글의 결·시대·개념을 은은히 환기 — fergusfinn 감성).
- 각 컨셉마다 검색어 세트(영어/라틴어, 작가명·유파·매체·시대 키워드)를 만든다.
- 매칭 강도는 사용자 승인대로 **"둘 다 고려해 제안"**: 후보 묶음에 직결형과 연상형이 섞이도록 한다.

### Step 3 — 검색 (Wikimedia 우선, 그 외 best-effort)
검증된 1차 소스와 보조 소스를 구분한다. **다섯 소스를 동급으로 취급하지 않는다.**

- **1차 (검증 완료 — Wikimedia Commons)**: MediaWiki API로 직접 래스터 URL·라이선스·작가·연도를 한 번에 얻는다.
  ```
  https://commons.wikimedia.org/w/api.php?action=query&generator=search
    &gsrsearch=<검색어>&gsrnamespace=6&gsrlimit=<N>
    &prop=imageinfo&iiprop=url|extmetadata|mime|size
    &iiurlwidth=1200
    &format=json
  ```
  - **User-Agent 헤더 필수** (없으면 API가 거부). 예: `banner-doc-skill/<ver> (contact)`.
  - 반환 필드 매핑 (실호출로 검증됨):
    - `imageinfo[0].url` → 원본 풀 래스터 URL (`upload.wikimedia.org/...`, 핫링크 가능).
    - `imageinfo[0].thumburl` (`iiurlwidth=1200`가 만든 크기 조정 URL) → **배너 값으로 우선 사용** (풀 원본은 수천만 픽셀·수 MB라 로딩 과중). 썸 URL도 Wikimedia에서 안정 캐시됨. thumburl이 없으면 `url`로 폴백.
    - `imageinfo[0].mime` → `image/*` 인지 확인 (PDF·SVG 등 걸러냄; 배너엔 jpg/png/webp만).
    - `extmetadata.LicenseShortName.value` → 라이선스 (예: `Public domain`, `CC BY-SA 4.0`).
    - `extmetadata.Artist.value` → 작가. **HTML(`<bdi><a>…</a></bdi>`)이 섞여 있으므로 태그를 제거해 평문화**한 뒤 `banner_creator`에 기록.
    - `extmetadata.DateTimeOriginal.value` (또는 `DateTime`) → 연도.
    - `imageinfo[0].descriptionurl` → 출처 페이지 URL (`banner_source`).
- **보조 (best-effort — 소스별로 직접 래스터 URL 추출 난이도가 다름)**: Met Open Access API(`isPublicDomain`, `primaryImage`), Rijksmuseum API, NYPL, Internet Archive 등. **여러 소스가 IIIF 뷰어/아이템 페이지만 주고 직접 래스터 URL을 깔끔히 안 주므로** 이들은 "직접 URL을 안정적으로 뽑을 수 있을 때만" 사용한다. 못 뽑으면 그 후보는 스킵.
- 현실적 형태: **Wikimedia 우선 + 나머지 보강**. 커맨드 문서도 이렇게 서술한다("다섯 소스 동급"이라고 쓰지 않는다).

### Step 4 — 감별 (vetting)
- **라이선스 필터**: 소스가 **PD / CC0 / 자유 라이선스(CC BY·CC BY-SA 등)로 태깅한 것만** 통과. 라이선스 필드가 없거나 모호하면 후보에서 제외. (§6 하드룰 참조 — 이 스킬은 저작권을 독자 판단하지 않고 소스의 태깅을 신뢰한다.)
- **눈으로 확인**: 통과 후보의 **썸네일(`iiurlwidth`로 얻은 800px급)**을 `Bash`(curl)로 스크래치패드에 임시 저장 → `Read`로 실제 이미지를 본다(볼트엔 저장 안 함). 판정:
  - 미적 적합성 — 고판화 특유의 고대비·인쇄판 질감, fergusfinn류 스칼라리 감성.
  - 실사용 가능성 — "글자만 빼곡한 문서 스캔", "로고/작은 아이콘", "저해상·손상 스캔" 배제.
  - 관련성 — 도출한 컨셉(직결/연상)에 부합.
- **폴백**: 특정 소스가 안정적 직접 URL을 안 주면 스킵하고 다른 소스로. **최소 2개 확보 실패 시** 사용자에게 검색어 조정을 요청(중단).

### Step 5 — 후보 제시 & 선택
- 최종 2~3개를 `AskUserQuestion`으로 제시. 각 옵션:
  - `label`: 짧은 제목(작가·소재).
  - `description`: **클릭 가능한 이미지 URL** + (원제·작가·연도·라이선스·이 글에 맞는 이유 한 줄).
- 항상 **"다 별로 → 재검색"** 옵션 포함.
- **멱등성 (§ 어드바이저 지적 반영)**: 입력 노트에 이미 `banner` 필드가 있으면, 제시 전에 **현재 배너 URL을 먼저 알리고**, 선택지에 **"현재 배너 유지"**를 함께 넣는다. 즉 재실행이 정상 흐름이며, 사용자가 후보를 고르면 기존 `banner*` 필드를 **덮어쓴다**(비-banner 필드는 보존). 사용자가 "유지"를 고르면 아무것도 바꾸지 않고 종료.
- **제시 UX 대안 (선택 — 강제 아님)**: `AskUserQuestion`은 이미지를 렌더하지 못해 사용자가 URL을 일일이 클릭해 비교해야 한다. 이미 감별용으로 후보 썸네일을 스크래치패드에 받아두므로, 이를 **data-URI로 인라인한 작은 Artifact 컨택트시트**(2~3개 나란히)로 만들면 한눈에 비교 가능(원격 이미지를 막는 Artifact CSP를 data-URI가 우회). 초판은 텍스트 제시로 시작하고, 이 옵션은 후속 개선으로 남긴다.

### Step 6 — 적용 (제자리)
선택된 후보를 프론트매터에 기록. **그 외 필드·본문은 바이트 단위 보존**:
```yaml
banner: <배너 이미지 URL — thumburl 우선>
banner_source: <출처 페이지 URL>
banner_license: <라이선스 표기>
banner_title: <원작 제목>
banner_creator: <작가/판각자 — HTML 제거 평문>
banner_year: <연도>
```
- 프론트매터가 있으면 위 `banner*` 필드만 추가/갱신, 나머지 필드·순서·값 보존.
- 프론트매터가 없으면 위 필드만 담은 최소 블록 생성. `title` 등 다른 필드를 날조하지 않는다(tag-doc 규약).
- `Edit`(신규 블록 생성 시에만 `Write`)로 **입력 파일 자체**를 수정. 사본·백업 안 만듦(git이 소스 관리).

### Step 7 — 리포트
간결 블록 하나:
```
✓ Banner → <input_path>
  · 주제 신호: <frontmatter|filename|body-h1>
  · 선택: <원제> — <작가>, <연도>
  · 라이선스: <license>
  · 출처: <descriptionurl>
  · banner 필드: <생성|갱신(이전 값 덮어씀)>
  · 전제: Pixel Banner "URL 이미지 허용" 설정이 켜져 있어야 렌더됨
```
문서 본문은 출력하지 않는다.

## 5. 자연어 인터페이스 (커맨드 문서 상단)

- 트리거: `/banner-doc <파일경로>`.
- 문서에 명시: 이 커맨드는 웹 검색·이미지 조회를 하며(외부 네트워크 접근), Pixel Banner의 URL 배너 설정이 전제라는 점.

## 6. 하드룰

- **라이선스 — 소스 태깅 신뢰(독자 법 판단 아님)**: 소스가 PD/CC0/자유 라이선스로 태깅한 이미지만 사용. 라이선스 필드가 없거나 모호하면 스킵. (저작권을 스킬이 독립적으로 판정하지 않는다 — 이 표현을 그대로 문서에 쓴다.)
- **직접 URL만**: HTML 파일 페이지가 아니라 실제 래스터 이미지 URL. `mime`이 `image/*`(jpg·png·webp)인지 확인. SVG·PDF·GIF 배너 배제.
- **원격 참조 전용**: 볼트에 이미지 다운로드 안 함(임시 감별용 스크래치패드는 예외, 볼트 밖).
- **제자리 편집**: 기존 프론트매터 필드·본문 바이트 단위 보존. `_banner` 사본 금지. 백업 안 함.
- **내용 불변**: 본문 절대 불변. 프론트매터의 `banner*` 필드만.
- **네트워크 규약**: Wikimedia API 호출 시 User-Agent 헤더 필수. 개인정보·인증 토큰을 쿼리에 넣지 않음.

## 7. 전제조건 · 리스크

- **전제**: Pixel Banner 설정 "URL 이미지 허용"(Show banner from URL)이 켜져 있어야 원격 URL 배너가 렌더됨. 스킬은 플러그인 설정을 바꾸지 않으며, 리포트에서 이 전제를 상기시킨다.
- **리스크 — 핵심은 "소스별 직접 URL 추출"**: CORS는 비이슈(Pixel Banner는 `<img>`로 렌더, fetch 아님). 진짜 리스크는 소스마다 직접 래스터 URL·라이선스 필드를 뽑는 방식이 다르다는 것 → Wikimedia 우선, 나머지 best-effort로 대응.
- **리스크 — 검색 히트 부족**: 연상형은 검색어 품질에 민감. 최소 2개 확보 실패 시 사용자에게 검색어 조정 요청(중단), 임의 저품질 후보로 채우지 않음.
- **리스크 — 작가 필드 HTML**: `extmetadata.Artist`는 HTML 포함 → 태그 제거 후 기록.

## 8. 검증 근거 (설계 확정 전 실호출)

- Wikimedia Commons API를 `Cellarius celestial map`로 실호출 → 3건 모두 `upload.wikimedia.org` 직접 JPG URL, `License: Public domain`, `Artist`(HTML 포함), `Date`(1660·1661) 정상 반환 확인. 파이프라인의 1차 소스 메커니즘 실재 검증 완료.

## 9. YAGNI — 명시적 비목표

- 이미지 볼트 다운로드/로컬 호스팅 (사용자가 원격 URL 선택).
- Pixel Banner 아이콘·위치(`banner-icon`·`banner-y`) 세팅 (사용자가 기본값만 요청, 이미지 URL + 출처 메타만 건드림).
- 자율 무-확인 적용 (사용자가 후보 제시형 선택).
- 다국어 taxonomy·장르 분기 등 과도한 일반화.
- Artifact 컨택트시트는 초판 비목표(후속 개선 후보).
