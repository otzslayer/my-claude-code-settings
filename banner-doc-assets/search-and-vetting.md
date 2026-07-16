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

### 검색어 만들기 (컨셉당 1개)

각 컨셉마다 **영어/라틴어 검색어를 하나씩** 고른다(§ 호출 레시피 예산 — 컨셉 3개 × 검색어 1개).
노트가 한국어일 수 있으므로 검색은 반드시 영어/라틴어 개념어로 한다(Wikimedia Commons는 영어
메타데이터가 지배적). 아래 축을 **한 줄로 조합**해 하나를 만든다 — 변형을 여러 개 준비해 순차
시도하는 방식은 라운드트립만 먹는다:

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

### 텍스트 밀집 자료 주의

**필사본·팔림프세스트·고서 페이지**는 개념적으로 매력적일 때가 많다(팔림프세스트 = 지우고 다시
쓴 기록). 하지만 실물은 대개 **텍스트로 빽빽한 문서 스캔**이라 배너로 얹으면 갈색 텍스처로만
읽히고 § 감별 4에서 탈락한다. 메타데이터로는 미리 알 수 없으니 — 이건 눈으로 봐야 안다 —
**같은 컨셉을 시각적 구조가 있는 자료(도해·지도·판화)로 바꿔 잡는 편**이 낫다. 예: "기록의
재작성" → 팔림프세스트 대신 `geological cross section`·`meander belt map`(지층·물길로 과거가
층층이 남은 도판).

---

## § 1차 소스 개관 (Wikimedia 단일)

**1차 소스는 Wikimedia Commons 하나다.** 정상 경로는 Wikimedia만으로 최소 후보 수를 채우는
것이고, 못 채울 때만 § 보조 소스(LoC 포함)로 내려간다.

- **왜 단일인가** — Wikimedia 검색 JSON은 한 번의 호출로 래스터 URL·라이선스·mime·**width/height**를
  전부 준다. 즉 라이선스·mime·해상도 **3중 사전 필터가 추가 호출 없이 공짜**다. LoC를 비롯한 다른
  소스는 이 셋 중 일부를 검색 JSON에 담지 않아 후보당 별도 호출이 필요하고, 그 호출은 대부분
  탈락할 후보에 쓰인다(§ 보조 소스 — LoC).
- **transport** — **`Bash` curl + `-H 'User-Agent: …'` 헤더로 raw JSON을 발행**한다. `WebFetch`는
  금지(커스텀 헤더·raw JSON 불가). `WebSearch`/`WebFetch`는 § 보조 소스 탐색용이다. 구체적 호출은
  **§ 호출 레시피**를 그대로 따른다.
- **라이선스 태그** — `LicenseShortName`. 소스가 명시한 태그만 신뢰하며 저작권을 독자 판단하지
  않는다(§ 감별 1).
- LoC·NYPL·Met·Rijksmuseum·Internet Archive는 § 보조 소스(best-effort)다. **AIC(시카고 미술관)는
  Cloudflare 핫링크 불가로 배너 소스에서 제외**됐다(§ 보조 소스 하단 상세).

---

## § 호출 레시피 (필수 — 라운드트립 예산)

검색 단계의 지배적 비용은 토큰이 아니라 **Bash 라운드트립 수**다. 아래를 그대로 따르면 검색이
**Bash 2콜**로 끝난다. 벗어나면 아래 § 실측 함정에 걸린다.

### 예산

| 항목 | 상한 |
|---|---|
| 컨셉 | 3개 (직결형 ≥1 + 연상형 1~2) |
| 컨셉당 검색어 | **1개** |
| 검색 Bash 콜 | **1콜** (전 컨셉 fan-out) |
| 파싱 Bash 콜 | **1콜** (전 파일 일괄) |
| 시각 감별 `Read` | 통과 후보 **2~3개 확보까지** (하드 상한 아님 — § 감별 4) |

**빈 결과가 나온 검색어는 버린다.** 변형을 만들어 재시도하지 않는다 — 통과 후보가 2개 미만이면
사용자에게 검색어 조정을 요청하고 중단한다(§ 최소 확보 실패).

### 콜 1 — 전 컨셉 fan-out (파일로 저장)

```bash
cd <scratchpad>
f(){ curl -s -H 'User-Agent: banner-doc/1.0 (Claude Code; contact via user)' \
  "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=$2&gsrnamespace=6&gsrlimit=25&prop=imageinfo&iiprop=url%7Cextmetadata%7Cmime%7Csize&iiurlwidth=1200&format=json" -o "wm_$1.json"; }
f tree    "filetype%3Abitmap%20genealogical%20tree%20engraving"                  # 직결형
f meander "filetype%3Abitmap%20ancient%20courses%20mississippi%20meander%20belt"  # 연상형
f strata  "filetype%3Abitmap%20geological%20cross%20section%20engraving"          # 연상형
```

(예시는 "기록·계보·과거의 층" 결의 컨셉 3갈래. 실제 컨셉은 노트 주제에서 도출한다.)

**모든 `gsrsearch`는 `filetype%3Abitmap%20`으로 시작한다.** File 네임스페이스 전문 검색은 Internet
Archive의 PDF 책 스캔이 지배한다 — 빼면 § 감별 2의 mime 필터를 통과하는 후보가 0건에 수렴하고,
결과에 섞인 PDF 한 건이 검색 전체를 죽인다(§ 실측 함정).

### 콜 2 — 일괄 파싱 (라이선스·mime·해상도 필터 적용 후 컴팩트 표만 출력)

```bash
cd <scratchpad>
python3 - <<'EOF'
import json,glob,re
strip=lambda s: re.sub(r'<[^>]*>','',s or '').strip()
for fn in sorted(glob.glob('wm_*.json')):
    print('='*12, fn)
    pages=json.load(open(fn)).get('query',{}).get('pages',{})
    if not pages: print('  (none)'); continue
    for p in pages.values():
        ii=p['imageinfo'][0]; em=ii.get('extmetadata',{})
        if ii['mime'] not in ('image/jpeg','image/png','image/webp'): continue  # § 감별 2
        if (ii.get('width') or 0) < 1000: continue                              # § 감별 3
        print(f"* {p['title'][5:]}\n  {strip(em.get('LicenseShortName',{}).get('value'))} | "
              f"{ii.get('width')}x{ii.get('height')} | {strip(em.get('Artist',{}).get('value'))[:45]} | "
              f"{strip(em.get('DateTimeOriginal',{}).get('value'))[:30]}\n  {ii.get('thumburl') or ii.get('url')}")
EOF
```

최종 후보가 정해지면 같은 파일들을 한 번 더 파싱해 `descriptionurl`·`ObjectName` 등 기록용
필드를 뽑는다(§ 반환 필드 매핑). 재검색하지 않는다 — JSON은 이미 스크래치패드에 있다.

### RTK 상호작용 — `-o <file>`이 필수인 **진짜** 이유

이 환경에는 `PreToolUse:Bash` 훅(`~/.claude/hooks/rtk-rewrite.sh`)이 있어 **`curl …`을
`rtk curl …`로 자동 재작성**한다. 파이프·리다이렉트 유무와 **무관**하게 항상 재작성된다.

`rtk curl`은 토큰 최적화기라 **응답 본문 대신 "스키마 개요"를 stdout에 출력**한다:

```
{
  batchcomplete: string,
  continue: { continue: string, gsroffset: int }
  ...
```

즉 **stdout으로 나온 것은 JSON이 아니다.** 반면 `-o <file>`은 stdout을 거치지 않아 rtk가 가로챌
것이 없으므로 **파일에는 원본 응답 바이트가 그대로** 떨어진다. 실측 비교:

| 형태 | 파일/파서가 받는 것 |
|---|---|
| `curl … -o out.json` | **진짜 JSON** ✅ ← 레시피가 쓰는 형태 |
| `curl … > out.json` (셸 리다이렉트) | 스키마 개요 ❌ — **조용히** 잘못된다. 나중 파싱에서야 터져 원인이 멀어진다 |
| `curl … \| python3` | 스키마 개요 ❌ → `JSONDecodeError` |
| `rtk proxy curl … -o out.json` | 진짜 JSON ✅ (문서화된 명시적 우회 — `-o`가 막힐 때의 탈출구) |

**"파이프가 문제"가 아니다.** 문제는 **stdout 자체**다. 파이프를 리다이렉트로 바꾸는 "수정"은
증상만 조용하게 만들 뿐 더 나쁘다.

**RTK를 끄지 않는다.** `-o`가 이미 우회하고, 평범한 `curl -o`는 rtk가 없는 환경에서도 그대로
동작한다(훅은 rtk 부재 시 경고 후 통과시킨다). `rtk proxy`는 rtk 설치를 전제하므로 오히려
이식성이 낮다. 훅은 전역 `matcher: Bash`라 커맨드 단위 off 스위치도 없다.

### 그 밖의 실측 함정

| 함정 | 증상 | 규칙 |
|---|---|---|
| `filetype:bitmap` 누락 | IA의 PDF 책 스캔이 결과를 뒤덮어 mime 필터 후 **0건**. 게다가 PDF가 한 건이라도 섞이면 `iiurlwidth` 정규화가 실패해 **검색 자체가 `urlparamnormal` 에러**로 죽는다 | `gsrsearch`는 **`filetype%3Abitmap%20`으로 시작** |
| 검색어에 `+`를 공백으로 | 결과 0건 (조용히 실패) | `gsrsearch` 인코딩은 **`%20`만** |
| bash 연관배열 `${!Q[@]}` | zsh `bad substitution` | 셸은 **zsh**. 연관배열 대신 위 `f()` 반복 호출 |
| raw JSON 그대로 출력 | 한 묶음에 20k자 | 파싱 출력은 **후보당 2~3줄**로 투영 |

---

## § Wikimedia 1차 소스 (완전 배선)

**1차 소스는 Wikimedia Commons.** MediaWiki API 한 번의 호출로 래스터 URL·라이선스·mime·크기·
작가·연도를 모두 얻는다.

호출 방식은 **§ 호출 레시피**를 그대로 쓴다(여기서 반복하지 않는다). UA에는 도구·연락 식별을
넣는다 — Wikimedia 정책이며 누락 시 403. `gsrnamespace=6`은 File 네임스페이스.

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

### 정본 우선 — `Artist`가 원작자가 아닐 때

유명 PD 회화·판화는 Commons에 **원작 스캔(정본)**과 **미술관에서 찍은 사진본**이 나란히 있다.
사진본의 `Artist`는 **촬영자**, `DateTimeOriginal`은 **촬영 일자**, `LicenseShortName`은 **사진의
CC 라이선스**다. 필드를 곧이곧대로 기록하면 1766년 회화가
`Joseph Wright of Derby / circa 1766 / Public domain`이 아니라
`kitmasterbloke / 2025-12-11 / CC BY 4.0`으로 남는다 — 사진에 대해선 정확한 태깅이지만, 배너가
가리키는 **작품**에 대해선 오귀속이다.

**이건 파일 선택 tiebreaker이지 필터가 아니다.**

1. **판별 신호** — 제목 stem이 같은(= 같은 작품) 통과 후보들 중 `DateTimeOriginal`이 **역사적
   연도**인 것을 **최근 타임스탬프**인 것보다 우선한다. 최근 날짜는 "작품 연도가 아니라 촬영·업로드
   일자"라는 결정적 신호다. 보조 신호: `Artist`가 개인 닉네임이거나 `Photograph by …`, 또는
   오래된 작품인데 라이선스가 CC BY·CC BY-SA.
2. **6개 `banner*`는 한 파일에서 통째로 가져온다.** 사진본에서 URL만 빼고 `banner_creator`만
   원작자로 바꾸는 **필드 교차 혼합은 날조**다 — `banner_source`는 사진본을 가리키는데
   `banner_creator`는 원작자인 모순이 남는다. 파일을 통째로 고르거나, 통째로 버린다.
3. **정본이 없고 사진본만 통과하면 그 파일의 라이선스를 곧이곧대로 기록한다.** "PD 작품을 찍은
   사진이니 PD" 같은 재판정은 § 감별 1(저작권을 독자 판단하지 않고 소스 태깅만 신뢰)을 정면으로
   깨므로 하지 않는다.
4. **재검색하지 않는다** — 정본은 대개 같은 검색 결과 안에 이미 있다. 콜 2의 표를 다시 훑으면
   된다(§ 호출 레시피 예산).

### `DateTimeOriginal`의 `date QS:` 잔여물

값에 Wikidata 문장이 들러붙어
`circa 1766date QS:P571,+1766-00-00T00:00:00Z/9,P1480,Q5727902`처럼 오는 경우가 있다.
**`date QS:` 이후를 잘라** `circa 1766`만 남긴다. **그 이상은 하지 않는다** — 날짜 값은
`1660. Date published…` 등 형태가 제각각이라 범용 파서를 만들면 금세 취약해진다. 잘라낸 뒤에도
남는 잡음은 그대로 둔다.

이건 **미관 문제이지 아래 § 쓰기 안전(YAML 손상·키 주입 방지)과 다른 사안**이다. 잔여물을
잘랐든 아니든 인용·이스케이프는 그것대로 반드시 적용한다.

### 쓰기 안전 — 모든 소스 파생 값 (신뢰 불가)

위 6개 `banner*` 스칼라(URL 포함)는 **외부 신뢰 불가 값**이다. 노트에 기록하기 전:

1. **YAML 문자열로 인용/이스케이프** — 큰따옴표로 감싸고 내부 `"`·`\`를 이스케이프한다.
2. **개행·제어문자 제거**.
3. HTML 제거는 평문을 만들 뿐, YAML 구조 메타문자(`:`·선두 `-`·`#`·`|`·`"`)를 남긴다. 이스케이프
   없이 기록하면 악의적 소스 메타데이터가 프론트매터를 손상시키거나 외부 키를 주입할 수 있다.

이 방어는 tag-doc에는 불필요했다(자기생성 신뢰값). banner-doc은 소스 파생 값이라 필수다.

---

## § 보조 소스 — LoC (배선은 완전하되 1차 아님)

미 의회도서관 Prints & Photographs 온라인 카탈로그. 유일하게 **완전 배선된 보조 소스**다.

**호출 조건 — Wikimedia만으로 통과 후보가 2개 미만일 때만 부른다.** 매 실행 무조건 도는 소스가
아니다.

**왜 1차가 아닌가** — LoC 검색 JSON에는 **`width`/`height`도 라이선스 필드도 없다.** 그래서
Wikimedia가 검색 JSON 하나로 공짜로 끝내는 3중 사전 필터(§ 감별 1·2·3)를 LoC는 후보당 별도
호출(라이선스) + 실제 다운로드(해상도) 없이는 못 한다. 즉 **탈락할 후보에 라운드트립을 먼저
지불하는 구조**다. 이는 소스 품질 문제가 아니라 API 구조의 비대칭이며, § 보조 소스의 "직접 래스터
URL을 안정 추출 가능할 때만 보강한다"는 원칙과 같은 결이다.

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

## § 감별 휴리스틱

통과 순서: **라이선스 → mime → 해상도 → 시각 판정**. 앞의 셋은 Wikimedia 검색 JSON만으로 **추가
호출 없이** 판정되므로, 비싼 시각 확인(다운로드 + `Read`)은 셋을 모두 통과한 후보에만 쓴다.
§ 호출 레시피의 콜 2 파서가 1~3을 이미 적용하니, 표에 남은 것만 눈으로 보면 된다.

### 1. 라이선스 필터

- 소스가 **PD / CC0 / 자유 라이선스(CC BY · CC BY-SA 등)로 태깅한 것만** 통과.
- 라이선스 필드가 없거나 모호하면 **제외**.
- **스킬은 저작권을 독자 판단하지 않고 소스의 태깅을 신뢰한다.** 법적 판단은 스킬의 책임 범위
  밖이다 — `LicenseShortName` 등 소스가 명시한 라이선스 태그만 근거로 삼는다.

### 2. mime 필터

- `imageinfo[0].mime`이 `image/*`(`image/jpeg`·`image/png`·`image/webp`)인지 확인.
- SVG(`image/svg+xml`)·PDF·GIF는 배너로 부적합하므로 **배제**.

### 3. 해상도 게이트

- `imageinfo[0].width`가 **1000 미만이면 배제**한다. 배너는 노트 상단을 가로로 채우므로 저해상은
  얹는 순간 뭉개진다.
- 이 판정은 검색 JSON에 이미 들어 있어 **공짜**다. 다운로드하고 `Read`한 뒤에야 "작네" 하고
  버리는 것이 시각 감별 단계에서 가장 흔한 낭비였다 — 그 왕복을 여기서 없앤다.

### 4. 시각 판정

라이선스·mime·해상도를 통과한 후보의 썸네일(`iiurlwidth`로 얻은 1200px급 URL)을 `Bash`(curl)로
**스크래치패드에 임시 저장** → `Read`로 실제 이미지를 본다. **볼트엔 저장하지 않는다.**

**보는 순서** — ① 컨셉당 1장씩 먼저(직결형/연상형 믹스를 보존한다) → ② 그다음 해상도 높은 순.
아래 배제 사유는 **메타데이터로 알 수 없는 것들**이라 여기서 탈락이 나오는 건 설계상 정상이다.
탈락하면 같은 컨셉의 다음 후보로 **대체 `Read`**를 한 장 더 쓰고, **통과 후보 2~3개가 모이면
멈춘다**.

`Read`가 이 단계에서 가장 비싼 연산이지만 **횟수 상한을 걸지는 않는다** — 상한 때문에 통과
후보가 2개 미만인 채로 § 최소 확보 실패에 빠지면 전체 재검색(콜 1+2+추가 `Read`)을 부르는데,
그게 `Read` 한 장보다 훨씬 비싸다. 아끼려다 더 쓰는 구조를 만들지 않는다.

- **적합** — 고판화의 고대비·인쇄판 질감, 고지도·빈티지 도표의 선명한 선, 고전 회화의 구성.
  배너로 얹었을 때 상단에 걸쳐 읽히는 자료.
- **배제** — 문서 스캔(텍스트만 있는 페이지), 로고·엠블럼, 저해상·손상·얼룩, 워터마크 박힌
  것, 잘린 조각.
- **관련성** — 도출한 컨셉(직결/연상)에 실제로 부합하는가. 검색이 엉뚱하게 히트한 것 배제.

### 최소 확보 실패

라이선스·mime·시각을 모두 통과한 후보가 **2개 미만**이면, 임의 저품질 후보로 채우지 말고
사용자에게 **검색어 조정을 요청하고 중단**한다.
