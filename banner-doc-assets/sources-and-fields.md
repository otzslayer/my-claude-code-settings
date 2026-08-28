# banner-doc 소스 배선 참조

> `banner-doc-assets/search-and-vetting.md`(SSOT 본진)이 조건부로 가리키는 참조 파일이다.
> 매 실행에 필요하지 않은 것만 여기 둔다. 세 갈래 중 하나에 해당할 때만 읽는다.
>
> 1. **폴백** — 1차 소스 셋으로 통과 후보가 2개 미만이라 LoC나 그 밖의 소스로 내려갈 때
> 2. **필드 확인** — 파서가 낸 표 밖의 소스 필드를 직접 봐야 할 때
> 3. **레시피 수정** — 검색 쿼리를 손보려는 편집 세션일 때

---

## § Wikimedia 반환 필드 매핑

### 반환 필드 매핑 (`query.pages[*].imageinfo[0]`)

| 반환 필드 | 매핑 대상 | 비고 |
|---|---|---|
| `imageinfo[0].thumburl` (우선) / `imageinfo[0].url` (폴백) | `banner` | `iiurlwidth=1200`이 만든 썸 URL 우선, 없으면 원본 URL |
| `imageinfo[0].mime` | mime 필터 | `image/*`(jpg·png·webp) 확인 |
| `imageinfo[0].width` / `height` / `size` | 해상도 게이트 | **`width < 1000` 배제**(§ 감별 3). 다운로드 전 공짜로 걸러진다 |
| `extmetadata.LicenseShortName.value` | `banner_license` | 라이선스 필터의 근거 |
| `extmetadata.Artist.value` | `banner_creator` | **HTML 태그 제거 후** 아래 쓰기 안전 규칙 적용. 개인 닉네임·`Photograph by …`면 **사진본 신호** — § 정본 우선 |
| `extmetadata.DateTimeOriginal.value` (없으면 `DateTime`) | `banner_year` | `date QS:` 잔여물 절단(아래). 최근 타임스탬프면 **사진본 신호** — § 정본 우선 |
| `imageinfo[0].descriptionurl` | `banner_source` | Commons 파일 설명 페이지 URL |
| `imageinfo[0].url`의 파일명(원제) | `banner_title` | URL 마지막 세그먼트 → 확장자·`File:` 정리 |

### `extmetadata.Artist` HTML 평문화

`Artist.value`는 흔히 `<bdi><a href="…">이름</a></bdi>` 형태의 HTML이다. `banner_creator`에
넣기 전 **모든 HTML 태그를 제거해 평문화**한다(`<bdi>`·`<a>` 등 흔적 없이). 이름만 남긴다.

### `DateTimeOriginal`의 `date QS:` 잔여물

값에 Wikidata 문장이 들러붙어
`circa 1766date QS:P571,+1766-00-00T00:00:00Z/9,P1480,Q5727902`처럼 오는 경우가 있다.
**`date QS:` 이후를 잘라** `circa 1766`만 남긴다. **그 이상은 하지 않는다** — 날짜 값은
`1660. Date published…` 등 형태가 제각각이라 범용 파서를 만들면 금세 취약해진다. 잘라낸 뒤에도
남는 잡음은 그대로 둔다.

이건 **미관 문제이지 아래 § 쓰기 안전(YAML 손상·키 주입 방지)과 다른 사안**이다. 잔여물을
잘랐든 아니든 인용·이스케이프는 그것대로 반드시 적용한다.

---

## § CMA 반환 필드 매핑

### 반환 필드 매핑 (`data[*]`)

| 반환 필드 | 매핑 대상 | 비고 |
|---|---|---|
| `images.print.url` | `banner` | 직접 `.jpg`. **`images.web`은 대개 900px 미만이라 쓰지 않고**, `images.full`은 `.tif`라 배제 |
| `images.print.width` / `height` | 해상도 게이트 | 검색 JSON에 이미 있어 공짜 |
| `share_license_status` | `banner_license` | `CC0` |
| `title` | `banner_title` | |
| `creators[*].description` | `banner_creator` | `Giulio Campagnola (Italian, 1482–1515)` 형태의 평문. HTML 평문화 불필요 |
| `creation_date` | `banner_year` | `c. 1508–9` 형태 |
| `url` | `banner_source` | `https://clevelandart.org/art/<accession>` |
| `type` | 시각 판정 힌트 | `Print`·`Painting`·`Photograph`. 사진이 섞여 나오므로 컨셉과 대조할 때 참고 |

6개 `banner*` 스칼라는 § 쓰기 안전(모든 소스 파생 값) 규칙을 동일하게 적용한다.

---

## § Wellcome 반환 필드 매핑

### 반환 필드 매핑 (`results[*]`)

| 반환 필드 | 매핑 대상 | 비고 |
|---|---|---|
| 조립한 IIIF URL | `banner` | 위 참조 |
| `items[*].locations[*].license.id` | `banner_license` | `pdm`(Public Domain Mark) 또는 `cc0`. 이 둘만 통과 |
| `title` | `banner_title` | |
| `contributors[*].agent.label` | `banner_creator` | 평문. 없으면 비운다 |
| `production[*].dates[0].label` | `banner_year` | `1822` 형태. 없으면 비운다 |
| `https://wellcomecollection.org/works/<id>` | `banner_source` | `results[*].id`로 조립 |

6개 `banner*` 스칼라는 § 쓰기 안전(모든 소스 파생 값) 규칙을 동일하게 적용한다.

---

## § 보조 소스 — LoC (배선은 완전하되 1차 아님)

미 의회도서관 Prints & Photographs 온라인 카탈로그. 보조 소스 중 유일하게 **완전 배선**돼 있다.

**호출 조건은 3소스 병렬로도 통과 후보가 2개 미만일 때뿐이다.** 매 실행 무조건 도는 소스가 아니다.

**왜 1차가 아닌가.** LoC 검색 JSON에는 **`width`/`height`도 라이선스 필드도 없다.** 1차 소스 셋이
검색 JSON 하나로 끝내는 사전 필터(§ 감별 1·2·3)를 LoC는 후보당 별도 호출(라이선스)과 실제
다운로드(해상도) 없이 하지 못한다. 즉 **탈락할 후보에 라운드트립을 먼저 지불하는 구조**다. 이는
소스 품질 문제가 아니라 API 구조의 비대칭이고, § 보조 소스의 "직접 래스터 URL을 안정 추출 가능할
때만 보강한다"는 원칙과 같은 결이다.

### 1단계 — 검색

```
https://www.loc.gov/pictures/search/?q=<검색어>&fo=json
```

```bash
curl -s -H 'User-Agent: banner-doc/1.0 (Claude Code; contact via user)' \
  'https://www.loc.gov/pictures/search/?q=steam%20engine&fo=json'
```

`results[*]`에서 뽑는다:

| 반환 필드 | 매핑 대상 | 비고 |
|---|---|---|
| `image.full` | `banner` | 직접 `.jpg` 래스터 URL(`tile.loc.gov/…`) |
| `title` | `banner_title` | |
| `creator` | `banner_creator` | 없으면 비운다 |
| `created_published_date` | `banner_year` | |
| `links.item` | `banner_source` | 아이템 페이지 URL |
| `pk` | (2단계 입력) | 라이선스 확인용 아이템 키 |

### 2단계 — 라이선스 태그 확인 (필수)

검색 JSON에는 **라이선스 필드가 없다.** 후보마다 아이템 JSON을 조회해 최상위 `unrestricted`
불리언을 확인한다:

```bash
curl -s -H 'User-Agent: banner-doc/1.0 (Claude Code; contact via user)' \
  'https://www.loc.gov/pictures/item/<pk>/?fo=json'
```

- 최상위 **`unrestricted == true` 인 항목만 통과**시켜 `banner_license`에
  `No known restrictions (LoC)`로 기록한다. `false`이거나 필드가 없으면 **제외**한다(§ 감별 1 —
  저작권을 독자 판단하지 않고 소스 태그만 신뢰).
- `image.full`은 `.jpg`이므로 mime 필터는 자동 충족(§ 감별 2).
- 6개 `banner*` 스칼라는 § 쓰기 안전(모든 소스 파생 값) 규칙을 동일하게 적용한다.

---

## § 보조 소스 (한 문단 원칙)

NYPL Digital Collections(API 토큰 필요)·Met Museum·Rijksmuseum·Internet Archive 등 다른 PD
소스는 **직접 래스터 URL을 안정적으로 추출할 수 있을 때만** best-effort로 보강한다. (LoC는 위
§ 보조 소스 — LoC에 완전 배선돼 있으니 폴백이 필요하면 그쪽을 먼저 쓴다.) 이들 상당수는
IIIF 뷰어·아이템 페이지만 노출하고 직접 이미지 URL을 안정적으로 주지 않으므로, 안 뽑히면 그
후보를 **스킵**한다. 개별 소스의 API 엔드포인트·IIIF 매니페스트 파싱을 여기에 열거하지 않는다 —
유지비만 늘고 실패율이 높다. 안정 URL 추출은 에이전트 재량의 best-effort이며, 못 뽑으면 미련
없이 버린다. 1차 소스(Wikimedia·LoC)만으로 최소 후보 수를 채우는 것이 정상 경로다.

**AIC(시카고 미술관) 제외** — AIC IIIF 이미지 호스트(`www.artic.edu/iiif/…`)는 Cloudflare 봇
차단 뒤에 있어 `AIC-User-Agent` 헤더나 `Referer: artic.edu` 없이는 403이다. Obsidian Pixel
Banner의 fetch는 이 조건을 못 붙이고 JS 챌린지도 못 풀어 **배너가 렌더되지 않음이 실측 확인**됐다
(서버측 이미지 프록시도 datacenter IP라 더 막힌다). 따라서 AIC는 1차·보조 어디에서도 배너 소스로
쓰지 않는다. AIC의 대표 PD 작품 상당수는 Wikimedia Commons에 미러링돼 있어 그쪽으로 커버된다.

---

---

## § 검색 연산자 실측 기록 (레시피 수정용)

### 효과가 없어서 버린 연산자 (재시도 금지)

기준 질의 `filetype:bitmap "genealogical tree" engraving`(71건)에 하나씩 얹어 실측한 결과다.

| 시도 | 결과 | 판정 |
|---|---|---|
| `-incategory:"Files from Internet Archive Book Images Flickr stream"` | 64건 → 63건 | 카테고리명은 맞지만 효과가 1건. 쿼리만 길어진다 |
| `incategory:"Engravings"` | **0건** | `incategory`는 **직접 소속만** 본다. 상위 카테고리는 하위만 거느려 직접 파일이 없다 |
| `deepcategory:"Genealogical trees"` | **0건** | 이 엔드포인트에서 동작하지 않는다 |
| CMA `&type=Print` | **0건** (`geological` 9건 중) | 결과 수가 적은 소스에 하드 필터를 걸면 통째로 비운다. `type`은 § CMA 반환 필드 매핑처럼 **시각 판정 힌트로만** 쓴다 |

---
