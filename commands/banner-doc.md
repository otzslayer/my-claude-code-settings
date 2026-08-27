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

### Step 2 — 비주얼 컨셉 3갈래
자산 § 컨셉 도출에 따라 **최소 1개 직결형 + 1~2개 연상형** 컨셉을 만든다(총 3개). 후보 묶음에
둘이 섞이도록. **컨셉당 영어/라틴어 검색어 1개**만 고른다 — 변형을 쌓지 않는다.

### Step 3 — 검색 (Bash 2콜)
**1차 소스는 Wikimedia Commons · CMA · Wellcome Collection 셋을 병렬로** 쓴다. 셋 다 인증 키가
필요 없고, 같은 fan-out 콜에 함께 들어가므로 소스가 늘어도 라운드트립은 2콜 그대로다. 자산
**§ 호출 레시피를 그대로 실행**한다:

1. **콜 1** — 3소스 × 전 컨셉을 한 번의 `Bash`로 fan-out해 스크래치패드에 `wm_<컨셉>.json`·
   `cma_<컨셉>.json`·`wel_<컨셉>.json`으로 저장하고, **같은 콜에서 볼트의 기존 `banner:` 값을
   `used_banners.txt`로 거둔다**(자산 § 중복 배제). 볼트 루트는 입력 파일에서 위로 거슬러 올라가며
   `.obsidian/`을 찾아 정한다.
   - **`-o`는 필수다.** RTK 훅이 `curl`을 `rtk curl`로 재작성하고 `rtk curl`은 stdout에 본문 대신
     **스키마 개요**를 뱉으므로, 파이프(`| python`)도 리다이렉트(`> file`)도 JSON을 얻지 못한다
     (자산 § RTK 상호작용).
   - 셸은 **zsh**다(bash 연관배열 금지). 검색어 인코딩은 소스마다 다르다: Wikimedia는 **`%20`만**
     (`+`는 0건), CMA와 Wellcome은 **`+`**. CMA의 `q`는 전 필드 AND라 **낱말 1~2개**로 줄인다.
2. **콜 2** — 저장된 JSON 전부를 한 번에 파싱해 **라이선스·mime·해상도 필터와 중복 배제를 적용한
   컴팩트 표**만 출력한다(후보당 2~4줄). raw JSON은 출력하지 않는다.

- 배너 값: Wikimedia는 `thumburl` 우선에 `url` 폴백, CMA는 `images.print.url`, Wellcome은
  `https://iiif.wellcomecollection.org/image/<ID>/full/1024,/0/default.jpg`로 조립한다.
- **후보 반복을 막는 장치는 셋이다** — 소스 다변화, 볼트·실행 내 중복 배제, 통과 후보를 섞어
  출력하기(`gsrlimit=40` + 셔플). `gsrsort=random`은 관련도를 통째로 버리므로 쓰지 않는다.
- **빈 결과 검색어는 버린다.** 변형으로 재시도하지 않는다.
- **폴백** — 통과 후보가 2개 미만일 때만 보조 소스로 내려간다: **LoC**(자산 § 보조 소스 — LoC,
  2-콜: 검색 `image.full` → 아이템 JSON `unrestricted==true`만 통과) → 그 외 NYPL·Met·
  Rijksmuseum·Internet Archive는 **직접 래스터 URL을 안정 추출 가능할 때만** best-effort.
- **AIC(시카고 미술관)는 배너 소스에서 제외** — Cloudflare 핫링크 불가(자산 § 보조 소스 하단).

### Step 4 — 감별 (컨택트 시트 `Read` 1회)
자산 § 감별 휴리스틱 순서대로: **라이선스(PD/CC0/자유만) → mime(image/* 만, SVG·PDF·GIF 배제)
→ 해상도(폭 1000 미만 배제) → 중복 배제 → 시각 판정**.

앞의 넷은 Step 3의 콜 2 파서가 이미 적용했으므로 남은 일은 **시각 판정뿐**이다. 후보를 한 장씩
`Read`하지 **않는다**. 표에서 고른 6~9개를 curl로 스크래치패드에 받아 `montage`로 격자 시트
하나(`sheet.jpg`)로 합친 뒤 **`Read` 한 번**으로 본다(자산 § 감별 4). 이 단계가 스킬에서 가장
느린 곳이었고, 시트가 그 지연을 후보 수만큼 나눈다. **볼트엔 저장하지 않는다.**

- 받은 파일이 **0바이트면 그 자리에서 버린다.** Wellcome IIIF는 사다리 밖 크기를 HTTP 200 +
  빈 몸통으로 돌려주므로, 이 검사가 Wellcome의 해상도 게이트를 겸한다.
- 시트에 담는 순서는 **컨셉당 1장 → 소스가 섞이도록**. 한 소스가 시트를 독점하면 반복 문제가
  되돌아온다.
- `montage`가 없으면 한 장씩 `Read`하는 옛 방식으로 내려간다. 이걸 위해 무엇도 설치하지 않는다.
- 시각 탈락은 정상이다. 통과가 2개 미만이면 다음 후보로 시트를 한 번 더 만든다. 시트 재생성에
  **하드 상한은 걸지 않는다**(자산 § 감별 4).

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

- **Wikimedia 한정** — `extmetadata.Artist`의 HTML(`<bdi><a>…</a></bdi>`)을 **제거해 평문화**한
  뒤 `banner_creator`에. CMA `creators[*].description`·Wellcome `contributors[*].agent.label`·
  LoC `creator`는 평문이라 평문화가 필요 없다.
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
- **직접 URL만**: `image/*`(jpg·png·webp)인 직접 래스터 URL만. SVG·PDF·GIF 배제. mime 필드가 없는
  소스(CMA)는 URL 확장자로 판정한다(`.tif` 배제).
- **원격 참조 전용**: 볼트에 이미지를 다운로드하지 않는다. 시각 감별용 임시 저장은 스크래치패드
  (볼트 밖)에만 하고 사용 후 정리한다.
- **제자리 편집**: 입력 파일을 in-place 수정한다. `_banner` 사본·백업을 만들지 않는다(git이 소스
  관리).
- **본문 불변**: 본문은 바이트 단위 보존. `banner*` 6필드만 쓴다. `title` 등 다른 필드 날조 금지.
- **네트워크 규약**: API JSON 호출은 모두 **`Bash` curl + `-H 'User-Agent: …'` 헤더 필수**
  (`WebFetch` 금지 — 커스텀 헤더·raw JSON 불가). 인증 토큰을 쿼리에 넣지 않는다.
- **RTK 규약**: API 응답은 반드시 **`curl … -o <file>`**로 받는다. RTK 훅이 `curl`을 `rtk curl`로
  재작성해 stdout을 스키마 개요로 바꾸므로, 파이프·리다이렉트로는 JSON을 못 얻는다. RTK를 끄지
  않는다 — `-o`가 이미 우회한다(자산 § RTK 상호작용).
- **라운드트립 예산**: 검색은 **Bash 2콜**(3소스 fan-out → 일괄 파싱), 컨셉 3개에 소스별 검색어
  1개. raw JSON을 컨텍스트에 출력 금지(§ 호출 레시피). 시각 감별은 **컨택트 시트 `Read` 1회**가
  기본이고, 시트 재생성 횟수에는 상한을 걸지 않는다. 최소 2개 확보가 절약보다 우선한다.
- **중복 배제**: 볼트가 이미 쓴 배너와 한 실행 안에서 이미 내보낸 후보는 다시 제시하지 않는다.
  키는 URL 문자열이 아니라 작품 식별자로 잡는다(자산 § 중복 배제).
- **쓰기 안전**: 소스 파생 값은 신뢰 불가 → 노트에 기록 전 **YAML 인용/이스케이프·개행/제어문자
  제거**. HTML 제거만으로는 YAML 구조 메타문자가 남는다.
- **최소 2개 미확보 시 중단**: 임의 저품질 후보로 채우지 않는다.
- **멱등성/재실행이 정상 흐름**: 기존 `banner`가 있으면 현재 URL을 알리고 "현재 배너 유지" 옵션을
  제공한다. 재실행 시 `banner*`만 덮어쓰고 비-banner 필드는 보존한다.
