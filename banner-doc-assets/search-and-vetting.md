# banner-doc 검색·감별 SSOT

> banner-doc 검색·감별 SSOT — 커맨드(`commands/banner-doc.md`)가 이 파일을 읽어 사용한다.
> 검색 소스 우선순위·Wikimedia API 필드매핑·감별 휴리스틱·컨셉 도출 지식은 여기에만 존재한다.
> tag-doc ↔ tag-rules, translate-doc ↔ translationese-patterns 분리 구조와 동일.

이 파일은 공개 도메인(PD) 역사 이미지 — 고판화·고지도·빈티지 도표·고전 회화 — 를 노트 주제에
맞게 찾아, 라이선스가 깨끗한 직접 래스터 URL을 뽑고, 눈으로 감별하는 지식을 담는다.

---

## § 컨셉 도출 (직결형 + 연상형)

노트의 주제 신호(제목·파일명·첫 H1)를 읽어 **비주얼 컨셉을 2~3갈래**로 생성한다. 후보 묶음에
직결형과 연상형이 **섞이도록** 한다.

- **직결형(최소 1개)** — 주제어를 직접 매칭하는 이미지. 글이 "증기기관"이면 19세기 증기기관
  고판화, "천문학"이면 고천문도. 주제를 문자 그대로 시각화한 역사 자료.
- **연상형(1~2개)** — 글의 결·시대·개념을 환기하는 이미지. fergusfinn.com 커버 감성 — 주제를
  직접 그리지 않아도 정서·시대감이 통하는 자료. "분산 시스템"이면 고지도의 교역로망, "기억과
  누적"이면 중세 필사본·고서 삽화. 은유적으로 글에 맞는 자료.

### 검색어 세트 만들기

각 컨셉마다 **영어/라틴어 검색어 세트**를 만든다. 노트가 한국어일 수 있으므로 검색은 반드시
영어/라틴어 개념어로 한다(Wikimedia Commons는 영어 메타데이터가 지배적). 세트에 넣을 축:

- **작가·유파** — `Piranesi`, `Albrecht Dürer`, `Ortelius`, `Hokusai`, `Dutch Golden Age`
- **매체** — `engraving`, `etching`, `woodcut`, `lithograph`, `copperplate`, `mezzotint`,
  `illuminated manuscript`, `antique map`, `botanical illustration`
- **시대** — `17th century`, `medieval`, `Renaissance`, `Victorian`, `Edo period`
- **소재 개념어** — 주제를 라틴어·학명·역사 용어로: 천문 → `celestial map`, `astronomia`;
  해부 → `anatomical plate`, `Vesalius`; 식물 → `herbarium`, `botanical plate`.

### 한국어 주제 → 영어/라틴어 개념어 변환 예시

- "증기기관의 역사" → `steam engine engraving`, `industrial revolution lithograph`,
  `Victorian machinery illustration`
- "천문학 노트" → `celestial map`, `antique star chart`, `astronomia`, `Cellarius Harmonia`
- "분산 시스템 설계" (연상형) → `antique trade route map`, `Ortelius map`,
  `medieval network diagram`
- "식물 분류" → `botanical illustration`, `herbarium plate`, `Redouté`, `flora engraving`

---

## § Wikimedia 1차 소스 (완전 배선)

**1차 소스는 Wikimedia Commons.** MediaWiki API 한 번의 호출로 래스터 URL·라이선스·작가·연도를
모두 얻는다.

### 호출 transport — `Bash` curl + User-Agent 헤더 (필수)

이 API JSON 쿼리는 **반드시 `Bash` curl로, `-H 'User-Agent: …'` 헤더를 붙여** 발행한다.

- `WebFetch`는 **금지** — 커스텀 헤더 설정 불가, raw JSON 반환 불가라 UA 필수 요건(누락 시
  Wikimedia가 403 반환)과 `extmetadata` JSON 파싱을 만족하지 못한다.
- `WebSearch`/`WebFetch`는 **보조 소스(R6) 탐색·페이지 조회**용이며 1차 API 호출에는 쓰지 않는다.
- User-Agent에는 도구·연락 식별을 넣는다(Wikimedia 정책). 예:
  `User-Agent: banner-doc/1.0 (Claude Code; contact via user)`.

### API 엔드포인트 템플릿

```
https://commons.wikimedia.org/w/api.php
  ?action=query
  &generator=search
  &gsrsearch=<검색어>
  &gsrnamespace=6
  &gsrlimit=20
  &prop=imageinfo
  &iiprop=url|extmetadata|mime|size
  &iiurlwidth=1200
  &format=json
```

curl 예시(URL 인코딩 유의, `gsrnamespace=6`은 File 네임스페이스):

```bash
curl -s -H 'User-Agent: banner-doc/1.0 (Claude Code; contact via user)' \
  'https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=celestial%20map%20engraving&gsrnamespace=6&gsrlimit=20&prop=imageinfo&iiprop=url%7Cextmetadata%7Cmime%7Csize&iiurlwidth=1200&format=json'
```

### 반환 필드 매핑 (`query.pages[*].imageinfo[0]`)

| 반환 필드 | 매핑 대상 | 비고 |
|---|---|---|
| `imageinfo[0].thumburl` (우선) / `imageinfo[0].url` (폴백) | `banner` | `iiurlwidth=1200`이 만든 썸 URL 우선, 없으면 원본 URL |
| `imageinfo[0].mime` | mime 필터 | `image/*`(jpg·png·webp) 확인 |
| `imageinfo[0].size` / `width` / `height` | 품질 참고 | 저해상 배제 판단 |
| `extmetadata.LicenseShortName.value` | `banner_license` | 라이선스 필터의 근거 |
| `extmetadata.Artist.value` | `banner_creator` | **HTML 태그 제거 후** 아래 쓰기 안전 규칙 적용 |
| `extmetadata.DateTimeOriginal.value` (없으면 `DateTime`) | `banner_year` | |
| `imageinfo[0].descriptionurl` | `banner_source` | Commons 파일 설명 페이지 URL |
| `imageinfo[0].url`의 파일명(원제) | `banner_title` | URL 마지막 세그먼트 → 확장자·`File:` 정리 |

### `extmetadata.Artist` HTML 평문화

`Artist.value`는 흔히 `<bdi><a href="…">이름</a></bdi>` 형태의 HTML이다. `banner_creator`에
넣기 전 **모든 HTML 태그를 제거해 평문화**한다(`<bdi>`·`<a>` 등 흔적 없이). 이름만 남긴다.

### 쓰기 안전 — 모든 소스 파생 값 (신뢰 불가)

위 6개 `banner*` 스칼라(URL 포함)는 **외부 신뢰 불가 값**이다. 노트에 기록하기 전:

1. **YAML 문자열로 인용/이스케이프** — 큰따옴표로 감싸고 내부 `"`·`\`를 이스케이프한다.
2. **개행·제어문자 제거**.
3. HTML 제거는 평문을 만들 뿐, YAML 구조 메타문자(`:`·선두 `-`·`#`·`|`·`"`)를 남긴다. 이스케이프
   없이 기록하면 악의적 소스 메타데이터가 프론트매터를 손상시키거나 외부 키를 주입할 수 있다.

이 방어는 tag-doc에는 불필요했다(자기생성 신뢰값). banner-doc은 소스 파생 값이라 필수다.

---

## § 보조 소스 (한 문단 원칙)

Met Museum·Rijksmuseum·NYPL Digital Collections·Internet Archive 등 다른 PD 소스는
**직접 래스터 URL을 안정적으로 추출할 수 있을 때만** best-effort로 보강한다. 이들 상당수는
IIIF 뷰어·아이템 페이지만 노출하고 직접 이미지 URL을 안정적으로 주지 않으므로, 안 뽑히면 그
후보를 **스킵**한다. 개별 소스의 API 엔드포인트·IIIF 매니페스트 파싱을 여기에 열거하지 않는다 —
유지비만 늘고 실패율이 높다. 안정 URL 추출은 에이전트 재량의 best-effort이며, 못 뽑으면 미련
없이 버린다. 1차 소스(Wikimedia)만으로 최소 후보 수를 채우는 것이 정상 경로다.

---

## § 감별 휴리스틱

통과 순서: **라이선스 필터 → mime 필터 → 시각 판정**. 이 순서로 걸러야 시각 확인 비용(썸네일
다운로드)을 라이선스·mime가 이미 통과한 후보에만 쓴다.

### 1. 라이선스 필터

- 소스가 **PD / CC0 / 자유 라이선스(CC BY · CC BY-SA 등)로 태깅한 것만** 통과.
- 라이선스 필드가 없거나 모호하면 **제외**.
- **스킬은 저작권을 독자 판단하지 않고 소스의 태깅을 신뢰한다.** 법적 판단은 스킬의 책임 범위
  밖이다 — `LicenseShortName` 등 소스가 명시한 라이선스 태그만 근거로 삼는다.

### 2. mime 필터

- `imageinfo[0].mime`이 `image/*`(`image/jpeg`·`image/png`·`image/webp`)인지 확인.
- SVG(`image/svg+xml`)·PDF·GIF는 배너로 부적합하므로 **배제**.

### 3. 시각 판정

라이선스·mime를 통과한 후보의 썸네일(`iiurlwidth`로 얻은 800px급 URL)을 `Bash`(curl)로
**스크래치패드에 임시 저장** → `Read`로 실제 이미지를 본다. **볼트엔 저장하지 않는다.**

- **적합** — 고판화의 고대비·인쇄판 질감, 고지도·빈티지 도표의 선명한 선, 고전 회화의 구성.
  배너로 얹었을 때 상단에 걸쳐 읽히는 자료.
- **배제** — 문서 스캔(텍스트만 있는 페이지), 로고·엠블럼, 저해상·손상·얼룩, 워터마크 박힌
  것, 잘린 조각.
- **관련성** — 도출한 컨셉(직결/연상)에 실제로 부합하는가. 검색이 엉뚱하게 히트한 것 배제.

### 최소 확보 실패

라이선스·mime·시각을 모두 통과한 후보가 **2개 미만**이면, 임의 저품질 후보로 채우지 말고
사용자에게 **검색어 조정을 요청하고 중단**한다.
