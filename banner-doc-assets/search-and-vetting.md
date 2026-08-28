# banner-doc 검색·감별 SSOT

> banner-doc 검색·감별 SSOT — 커맨드(`commands/banner-doc.md`)가 이 파일을 읽어 사용한다.
> 검색 소스 우선순위·소스별 API 필드매핑·중복 배제·감별 휴리스틱·컨셉 도출 지식은 여기에만 존재한다.
> tag-doc ↔ tag-rules, translate-doc ↔ translationese-patterns 분리 구조와 동일.

이 파일은 공개 도메인(PD) 역사 이미지 — 고판화·고지도·빈티지 도표·고전 회화 — 를 노트 주제에
맞게 찾아, 라이선스가 깨끗한 직접 래스터 URL을 뽑고, 눈으로 감별하는 지식을 담는다.

---

## § 컨셉 도출 (직결형 + 연상형)

노트의 주제 신호(제목·파일명·첫 H1)와 **본문**을 함께 읽어 **비주얼 컨셉을 2~3갈래**로 생성한다.
후보 묶음에 직결형과 연상형이 **섞이도록** 한다.

**제목만으로 컨셉을 짜지 않는다.** 제목은 대개 낱말 두셋이라 검색어로 옮기면 뜻이 넓은 일반어가
되고, 그 검색이 관련도가 낮은 후보를 부른다. 본문은 Step 1에서 이미 읽어 컨텍스트에 있으므로
**본문을 쓰는 데 드는 추가 비용이 없다.** 본문에서 다음을 건져 검색어에 반영한다.

- **고유 명사** — 인물·지명·기관·저작 이름. 검색어에서 가장 강한 신호다.
- **시대와 지역** — 본문이 다루는 연대나 문화권. § 검색어 만들기의 시대 축을 여기서 채운다.
- **되풀이되는 은유와 결** — 연상형 컨셉의 재료다. 제목에는 거의 드러나지 않는다.

제목이 "분산 시스템 설계"뿐이어도, 본문이 합의 알고리즘과 장애 전파를 다룬다면 연상형은
`medieval network diagram` 같은 막연한 어구가 아니라 본문의 결을 짚은 어구로 잡을 수 있다.

- **직결형(최소 1개)** — 주제어를 직접 매칭하는 이미지. 글이 "증기기관"이면 19세기 증기기관
  고판화, "천문학"이면 고천문도. 주제를 문자 그대로 시각화한 역사 자료.
- **연상형(1~2개)** — 글의 결·시대·개념을 환기하는 이미지. fergusfinn.com 커버 감성 — 주제를
  직접 그리지 않아도 정서·시대감이 통하는 자료. "분산 시스템"이면 고지도의 교역로망, "기억과
  누적"이면 중세 필사본·고서 삽화. 은유적으로 글에 맞는 자료.

### 검색어 만들기 (컨셉당 1개)

각 컨셉마다 **영어/라틴어 검색어를 하나씩** 고른다(§ 호출 레시피 예산). 소스마다 검색어 문법이
달라서, Wikimedia는 어구를 그대로 쓰고 CMA는 낱말 1~2개로 줄인다(§ 호출 레시피 콜 1).
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

## § 1차 소스 개관 (3소스 병렬)

1차 소스는 **Wikimedia Commons · Cleveland Museum of Art(CMA) · Wellcome Collection** 셋이다.
셋 다 인증 키가 필요 없고, 검색 응답 하나에 라이선스와 직접 래스터 URL이 함께 담겨 온다. 매
실행에서 셋을 **같은 fan-out 콜에 함께** 넣어 부르므로 소스가 늘어도 Bash 라운드트립은 그대로
2콜이다.

셋을 병렬로 두는 까닭은 **후보 반복**이다. Wikimedia 단일 시절에는 검색 랭킹이 결정적이라 비슷한
주제의 노트가 같은 상위 파일을 계속 뽑았다. 소장품이 서로 겹치지 않는 소스를 섞는 것이 그 반복을
푸는 가장 직접적인 방법이고, § 중복 배제가 나머지 절반을 맡는다.

| 소스 | 성격 | 검색 응답이 주는 것 | 배너 URL |
|---|---|---|---|
| Wikimedia Commons | 범용. 고지도·회화·판화 전반 | 라이선스·mime·width/height 전부 | `thumburl`, 없으면 `url` |
| CMA | 미술관 소장품. 판화·소묘·회화 | `share_license_status`, 이미지 3종의 width | `images.print.url` |
| Wellcome Collection | 의학·과학사 도해와 판화. 앞 둘과 겹침이 가장 적다 | 라이선스(`pdm`·`cc0`), IIIF 이미지 ID | IIIF `full/1024,/0/default.jpg` |

- **transport** — 셋 다 **`Bash` curl에 `-H 'User-Agent: …'`를 붙여 raw JSON**을 받는다.
  `WebFetch`는 금지한다(커스텀 헤더와 raw JSON을 쓸 수 없다). `WebSearch`·`WebFetch`는 § 보조 소스
  탐색용이다. 구체적 호출은 **§ 호출 레시피**를 그대로 따르고, 소스별 필드 매핑은 § Wikimedia
  1차 소스 · § CMA 1차 소스 · § Wellcome 1차 소스에 있다.
- **라이선스 태그** — 소스가 명시한 태그만 신뢰하며 저작권을 독자 판단하지 않는다(§ 감별 1).
- **LoC는 보조 소스로 남는다**(§ 보조 소스 — LoC). 3소스 병렬로도 통과 후보가 2개 미만일 때만
  부른다. 검색 JSON에 라이선스도 크기도 없어 후보당 추가 호출이 필요하다는 비대칭은 그대로다.
- NYPL·Met·Rijksmuseum·Internet Archive는 § 보조 소스(best-effort)다. **AIC(시카고 미술관)는
  Cloudflare 핫링크 불가로 배너 소스에서 제외**됐다(§ 보조 소스 하단 상세).

---

## § 호출 레시피 (필수 — 라운드트립 예산)

검색 단계의 지배적 비용은 토큰이 아니라 **Bash 라운드트립 수**다. 아래를 그대로 따르면 검색이
**Bash 2콜**로 끝난다. 벗어나면 아래 § 실측 함정에 걸린다.

### 예산

| 항목 | 상한 |
|---|---|
| 컨셉 | 3개 (직결형 1개 이상, 연상형 1~2개) |
| 컨셉당 검색어 | 소스별 **1개** (Wikimedia 어구 1개, CMA 낱말 1~2개, Wellcome 어구 1개) |
| 검색 Bash 콜 | **1콜** (3소스 × 전 컨셉 fan-out, 전부 `&` + `wait`) |
| 파싱 Bash 콜 | **1콜** (전 파일 일괄 + 중복 배제 + 6개 `banner*` 필드 출력) |
| 시트 Bash 콜 | **1콜** (다운로드 `&` + `wait` → `montage`) |
| 선택 후 Bash 콜 | **0콜** — 표가 필드를 다 냈으므로 재파싱하지 않는다 |
| 시각 감별 `Read` | **1회** (컨택트 시트 1장). 시트 재생성이 필요하면 추가 (§ 감별 4) |

### § 병렬화 (지연의 지배 요인)

이 스킬의 벽시계 시간은 토큰이 아니라 **네트워크 대기**가 지배한다. 검색 요청 7개와 시트 이미지
6장은 서로 의존하지 않으므로 전부 `&`로 띄우고 `wait` 한 번으로 받는다. 실측 효과는 아래와 같다.

| 구간 | 순차 | 병렬 | 비고 |
|---|---|---|---|
| 검색 fan-out (7 요청) | 9.19초 | **2.00초** | 콜 1 |
| 시트 다운로드 (6장) | 8.97초 / 13MB | **1.31초 / 2.3MB** | 콜 3. 축소 효과가 함께 들어 있다 |

**빈 결과가 나온 검색어는 버린다.** 변형을 만들어 재시도하지 않는다 — 통과 후보가 2개 미만이면
사용자에게 검색어 조정을 요청하고 중단한다(§ 최소 확보 실패).

### 콜 1 — 3소스 × 전 컨셉 fan-out (파일로 저장)

한 번의 `Bash` 안에서 세 소스를 모두 부르고, 같은 콜에서 **볼트가 이미 쓴 배너 URL 목록**까지
거둔다(§ 중복 배제). **모든 curl을 `&`로 띄우고 끝에서 `wait` 한 번**으로 받는다. 검색 요청은
서로 의존하지 않으므로 순차로 돌릴 이유가 없다. 실측에서 7개 요청이 **9.19초에서 2.00초**로
줄었다(§ 병렬화).

```bash
cd <scratchpad>
UA='User-Agent: banner-doc/1.0 (Claude Code; contact via user)'

wm(){ curl -s -H "$UA" \
  "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=$2&gsrnamespace=6&gsrlimit=40&prop=imageinfo&iiprop=url%7Cextmetadata%7Cmime%7Csize&iiurlwidth=1200&format=json" -o "wm_$1.json"; }
cma(){ curl -s -H "$UA" \
  "https://openaccess-api.clevelandart.org/api/artworks/?q=$2&cc0=1&has_image=1&limit=20" -o "cma_$1.json"; }
wel(){ curl -s -H "$UA" \
  "https://api.wellcomecollection.org/catalogue/v2/works?query=$2&items.locations.license=pdm&workType=k,e&include=items,contributors,production&pageSize=20" -o "wel_$1.json"; }

# 전부 백그라운드로 띄우고 한 번에 기다린다 (§ 병렬화)
wm  tree    "filetype%3Abitmap%20filew%3A%3E999%20genealogical%20tree%20engraving"          &  # 직결형
wm  meander "filetype%3Abitmap%20filew%3A%3E999%20ancient%20courses%20mississippi%20meander"  &  # 연상형
wm  strata  "filetype%3Abitmap%20filew%3A%3E999%20geological%20cross%20section%20engraving"   &  # 연상형
cma tree    "genealogy"          &   # CMA는 낱말 1~2개, 공백은 +
cma strata  "geological"         &
wel tree    "genealogical+tree"  &   # Wellcome은 어구 가능, 공백은 +
wel strata  "geological+strata"  &

# 이미 쓰인 배너 URL (VAULT는 입력 파일에서 .obsidian 을 찾아 위로 거슬러 올라간 경로)
grep -rhoE '^banner:[[:space:]]*.*' "$VAULT" --include='*.md' > used_banners.txt 2>/dev/null || : > used_banners.txt
wait
```

(예시는 "기록·계보·과거의 층" 결의 컨셉 3갈래다. 실제 컨셉은 노트 주제에서 도출한다.)

**Wikimedia의 모든 `gsrsearch`는 `filetype%3Abitmap%20filew%3A%3E999%20`로 시작한다.**

- `filetype:bitmap` — File 네임스페이스 전문 검색은 Internet Archive의 PDF 책 스캔이 지배하기
  때문에, 이를 빼면 § 감별 2의 mime 필터를 통과하는 후보가 0건에 수렴하고 결과에 섞인 PDF 한
  건이 검색 전체를 죽인다(§ 실측 함정).
- `filew:>999` — **해상도 게이트를 쿼리로 올린다.** 이게 없으면 `gsrlimit=40`으로 받아온 자리의
  상당수를 § 감별 3에서 어차피 탈락할 저해상 파일이 차지한다. 실측에서 이 연산자가 저해상 성서
  인물 썸네일을 밀어내고 큰 판본을 상위로 올렸다(71건 → 64건, 상위 4건이 전부 교체). 파서의 폭
  검사는 그대로 둔다. CMA·Wellcome·LoC에는 이 연산자가 없고, 쿼리에서 빠졌을 때의 방어가 된다.

**Wellcome은 `workType=k,e`(Pictures·Maps)로 좁힌다.** 이게 없으면 결과의 대부분이 책 서지
레코드다. 실측에서 `geological` 검색의 workType 분포는 Books 186 · Pictures 12 · Maps 1 · 기록물
1이었고, 필터를 걸자 200건이 13건으로 줄면서 **전부 IIIF 이미지가 있는 후보**가 됐다.

**소스마다 검색어 문법이 다르다.** Wikimedia는 공백을 `%20`으로만 인코딩하고, CMA와 Wellcome은
`+`를 쓴다. CMA의 `q`는 전 필드 AND 매칭이라 어구가 길면 0건이 되므로 **낱말 1~2개**로 줄인다
(실측: `geological engraving` 0건, `geological` 9건, `engraving+map` 19건). 컨셉 3개를 세 소스에
모두 태울 필요는 없다. **CMA와 Wellcome은 어울리는 컨셉에만** 붙여 2개씩이면 충분하다.

### 콜 2 — 일괄 파싱 (라이선스·mime·해상도 필터 + 중복 배제 후 컴팩트 표만 출력)

세 소스의 JSON 형태를 한 파서가 모두 처리하고, § 중복 배제를 같은 자리에서 적용한다. 순서는
**필터 → 중복 배제 → 관련도 정렬 → 상위 밴드 절단 → 밴드 안에서 셔플 → 5줄 출력**이다. 이 순서를
지켜야 한다. 밴드를 중복 배제보다 먼저 자르면 볼트에서 이미 쓴 항목이 밴드 자리를 먹어, 쓸 만한
후보가 남아 있는데도 출력이 비는 일이 생긴다.

```bash
cd <scratchpad>
python3 - <<'EOF'
import json,glob,re,random
from urllib.parse import unquote
strip=lambda s: re.sub(r'<[^>]*>','',s or '').strip()
def key(u):                                   # § 중복 배제 — 소스 넘어 같은 작품은 같은 키
    u=(u or '').split('?')[0]
    m=re.search(r'/image/([^/]+)/full/',u)
    if m: return 'wel:'+m.group(1)
    m=re.search(r'clevelandart\.org/([^/]+)/',u)
    if m: return 'cma:'+m.group(1)
    b=unquote(u.rsplit('/',1)[-1]); b=re.sub(r'^\d+px-','',b)
    m=re.search(r'[Ww]ellcome[_ ]([VLMN]\d{7})',b)   # WM에 미러된 Wellcome 스캔
    if m: return 'wel:'+m.group(1)
    return 'wm:'+b.lower()
seen=set()
try:
    for L in open('used_banners.txt',encoding='utf-8',errors='replace'):
        v=L.split(':',1)[1].strip().strip('"\'')
        if v: seen.add(key(v))
except FileNotFoundError: pass
NEW=SKIP=0
BAND=12                                       # 관련도 상위 몇 개 안에서만 섞을지
def stem(t):                                  # 같은 시리즈의 낱장을 한 묶음으로
    t=t.lower()
    t=re.sub(r'[,(]?\s*(plate|sheet|pl\.|folio|fol\.|no\.|vol\.|p\.|page|part|tafel|planche)\s*[.\d ivxlc]+','',t)
    t=re.sub(r'[\W_]+',' ',t).strip()
    return ' '.join(t.split()[:6])
def emit(rows,tag):                           # rows: (rank, key, title, line) — rank 작을수록 관련도 높음
    global NEW,SKIP
    out=[]; ser={}
    for r,k,t,line in sorted(rows,key=lambda x:x[0]):
        if k in seen: SKIP+=1; continue       # 중복 배제를 밴드 절단보다 먼저
        st=stem(t)
        if ser.get(st,0) >= 2: SKIP+=1; continue   # 한 시리즈에서 최대 2장
        ser[st]=ser.get(st,0)+1
        seen.add(k); out.append(line); NEW+=1
    band=out[:BAND]; random.shuffle(band)     # 관련도 밴드 안에서만 섞는다
    print('='*10,tag,f'({len(out)})')
    for line in band[:5]: print(line)

for fn in sorted(glob.glob('wm_*.json')):
    rows=[]
    for p in (json.load(open(fn)).get('query',{}).get('pages',{}) or {}).values():
        ii=(p.get('imageinfo') or [{}])[0]; em=ii.get('extmetadata',{})
        if ii.get('mime') not in ('image/jpeg','image/png','image/webp'): continue  # § 감별 2
        if (ii.get('width') or 0) < 1000: continue                                  # § 감별 3
        u=ii.get('thumburl') or ii.get('url')
        rows.append((p.get('index',999), key(u), p['title'][5:], f"* WM {p['title'][5:][:60]}\n  "
            f"{strip(em.get('LicenseShortName',{}).get('value'))} | {ii.get('width')}x{ii.get('height')} | "
            f"{strip(em.get('Artist',{}).get('value'))[:40]} | "
            f"{strip(em.get('DateTimeOriginal',{}).get('value'))[:24]}\n  {u}\n  src {ii.get('descriptionurl')}"))
    emit(rows,fn)

for fn in sorted(glob.glob('cma_*.json')):
    rows=[]
    for rank,a in enumerate(json.load(open(fn)).get('data',[]) or []):
        pr=(a.get('images') or {}).get('print') or {}     # web은 대개 900px 미만, full은 .tif
        u=pr.get('url','')
        if not u.endswith('.jpg'): continue
        if int(pr.get('width') or 0) < 1000: continue
        cr=', '.join(c.get('description','') for c in (a.get('creators') or []))
        rows.append((rank, key(u), a.get('title') or '', f"* CMA[{a.get('type')}] {(a.get('title') or '')[:55]}\n  "
            f"{a.get('share_license_status')} | {pr.get('width')}x{pr.get('height')} | {cr[:40]} | "
            f"{(a.get('creation_date') or '')[:24]}\n  {u}\n  src {a.get('url')}"))
    emit(rows,fn)

for fn in sorted(glob.glob('wel_*.json')):
    rows=[]
    for rank,w in enumerate(json.load(open(fn)).get('results',[]) or []):
        iid=lic=None
        for it in w.get('items') or []:
            for L in it.get('locations') or []:
                m=re.search(r'/image/([^/]+)/info\.json',L.get('url') or '')
                if m: iid,lic = m.group(1),(L.get('license') or {}).get('id')
        if not iid or lic not in ('pdm','cc0'): continue
        u=f'https://iiif.wellcomecollection.org/image/{iid}/full/1024,/0/default.jpg'
        cr=', '.join(c['agent']['label'] for c in (w.get('contributors') or []))
        yr=next((((pp.get('dates') or [{}])[0].get('label')) or '' for pp in (w.get('production') or [])),'')
        rows.append((rank, key(u), w['title'], f"* WEL {w['title'][:60]}\n  {lic} | 1024w(사다리 상한, 받아서 0바이트면 탈락) | "
            f"{cr[:40]} | {yr[:24]}\n  {u}\n  src https://wellcomecollection.org/works/{w['id']}"))
    emit(rows,fn)
print(f'\n-- 신규 {NEW}건 / 중복 배제 {SKIP}건')
EOF
```

**표에는 6개 `banner*` 필드가 전부 들어 있다.** 제목·라이선스·작가·연도·배너 URL에 더해 세 소스
모두 `src`(각각 Commons 파일 설명 페이지, CMA 작품 페이지, Wellcome 작품 페이지)를 함께 낸다.
그러니 사용자가 고른 뒤 **JSON을 다시 파싱하지 않는다.** 표가 이미 컨텍스트에 있으므로 Step 6은
Bash 라운드트립 없이 바로 쓰기로 간다. 재파싱은 왕복을 하나 더 쓸 뿐 아니라, 같은 값을 두 번
유도하면서 어긋날 여지를 만든다.

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
| raw JSON 그대로 출력 | 한 묶음에 20k자 | 파싱 출력은 **후보당 2~4줄**로 투영 |
| `generator=search`의 `pages`를 순회 순서대로 씀 | `pages`는 **pageid로 키를 잡은 딕셔너리**라 관련도 순위가 사라진다. 실측에서 순회 첫 항목은 관련도 1위가 아니라 무관한 책 스캔이었고, 진짜 1위는 네 번째에 나왔다 | 각 페이지의 **`index` 필드로 정렬**한 뒤 쓴다(§ 랭킹 고착을 푸는 법) |
| Wellcome을 `workType` 없이 검색 | 결과의 **93%가 책 서지 레코드**다(실측 `geological`: Books 186 · Pictures 12 · Maps 1). 배너로 쓸 후보가 뒤에 묻힌다 | `workType=k,e`(Pictures·Maps)를 건다 |
| Wellcome IIIF에 사다리 밖 크기 요청 | `1200,`·`full/full`이 **HTTP 200 + `image/jpeg` + 0바이트**로 온다. 에러가 아니라 빈 몸통이라 조용히 깨진다 | 폭은 **`1024,`로 고정**한다. 0바이트면 그 항목의 사다리 상한이 1024 미만(세로로 긴 자료)이라는 뜻이니 후보에서 버린다 |
| CMA `images.web`을 배너로 | 대개 **900px 미만**이라 § 감별 3에서 전멸 | **`images.print`**(jpg)를 쓴다. `images.full`은 `.tif`라 배제 |
| CMA `q`에 긴 어구 | 전 필드 AND 매칭이라 0건. 실측: `geological engraving` 0건, `geological` 9건 | CMA 검색어는 **낱말 1~2개**, 공백은 `+` |
| zsh에서 `rm -f wm_*.json` | 매치가 없으면 `no matches found`로 죽는다 | 정리는 `rm -f wm_*.json 2>/dev/null \|\| true` 형태로 |

---

## § 중복 배제 (반복을 푸는 절반)

소스를 늘려도 볼트에 이미 쓴 이미지를 다시 뽑으면 사용자 눈에는 그대로 반복이다. 그래서 파서는
**두 층위**로 배제한다.

1. **볼트 배제** — 콜 1이 거둔 `used_banners.txt`(볼트 전 노트의 `banner:` 값)의 키를 미리
   `seen`에 채운다. 볼트 루트는 **입력 파일에서 위로 거슬러 올라가며 `.obsidian/` 디렉터리를
   찾아** 정한다. 경로를 코드에 박지 않는다.
2. **실행 내 배제** — 유명 자료 하나가 컨셉 셋에 모두 걸리는 일이 흔하다. 한 실행 안에서도 이미
   출력한 키는 다시 내보내지 않는다.

**키는 URL 전체가 아니라 작품 식별자로 잡는다.** 같은 파일이 `1024px-`·`1280px-` 접두어나 `utm_*`
쿼리만 다른 채로 오면 문자열 비교는 다른 것으로 본다. 위 `key()`는 쿼리를 떼고, 픽셀 접두어를
벗기고, CMA는 accession 번호로, Wellcome은 IIIF 이미지 ID로 정규화한다. **Wikimedia에 미러된
Wellcome 스캔**(`…_Wellcome_V0025106.jpg`)도 파일명에서 ID를 뽑아 Wellcome 후보와 같은 키로
묶는다. 실측에서 이 교차 배제가 Wellcome 후보 3건 중 2건을 걸러냈다.

### 랭킹 고착을 푸는 법 (관련도를 지키면서)

**관련도를 먼저 복원하고, 그다음에 흔든다.** 순서가 반대면 다양성이 관련도를 잡아먹는다.

1. **관련도 정렬** — `generator=search`의 `query.pages`는 **pageid로 키를 잡은 딕셔너리**라 순회
   순서가 관련도 순이 아니다. 각 페이지의 **`index` 필드가 진짜 검색 순위**이므로 이 값으로
   정렬한다(§ 실측 함정). CMA와 Wellcome은 응답 배열 순서가 곧 순위다.
2. **밴드 절단** — 정렬된 통과 후보의 **상위 12개까지만** 후보로 삼는다. 풀 전체를 섞으면
   `gsrlimit=40`의 꼬리에 있는 무관한 결과가 상위와 같은 확률로 제시된다.
3. **시리즈 상한** — 제목에서 `Plate 22 Sheet 01` 같은 낱장 표기를 벗긴 **stem이 같은 후보는 최대
   2장**만 남긴다. § 중복 배제의 키는 파일 단위라 같은 지도·화첩의 낱장들을 서로 다른 것으로 보고,
   실측에서 한 컨셉의 출력 5줄이 같은 시리즈의 낱장 다섯 장으로 채워졌다. 관련도는 높지만 사용자가
   고를 것이 하나뿐인 상태라 반복과 같은 문제다.
4. **밴드 안에서 셔플** — 남은 것 중 상위 12개를 섞어 5개를 출력한다. 관련도 순위는 검색과 밴드가
   지키고, 흔드는 범위는 밴드 안으로 묶인다.

`gsrsort=random`은 **쓰지 않는다.** 실측에서 문법 오류 없이 동작하기는 하지만 관련도를 통째로
버려서, "geological engraving" 검색에 20420px짜리 무관한 책 스캔이 1위로 올라왔다.

### 효과가 없어서 버린 연산자 (재시도 금지)

기준 질의 `filetype:bitmap "genealogical tree" engraving`(71건)에 하나씩 얹어 실측한 결과다.

| 시도 | 결과 | 판정 |
|---|---|---|
| `-incategory:"Files from Internet Archive Book Images Flickr stream"` | 64건 → 63건 | 카테고리명은 맞지만 효과가 1건. 쿼리만 길어진다 |
| `incategory:"Engravings"` | **0건** | `incategory`는 **직접 소속만** 본다. 상위 카테고리는 하위만 거느려 직접 파일이 없다 |
| `deepcategory:"Genealogical trees"` | **0건** | 이 엔드포인트에서 동작하지 않는다 |
| CMA `&type=Print` | **0건** (`geological` 9건 중) | 결과 수가 적은 소스에 하드 필터를 걸면 통째로 비운다. `type`은 § CMA 반환 필드 매핑처럼 **시각 판정 힌트로만** 쓴다 |

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

## § CMA 1차 소스 (완전 배선)

Cleveland Museum of Art Open Access. 인증 키가 필요 없고, 검색 응답 하나에 CC0 여부와 직접 jpg
URL과 크기가 함께 온다.

```
https://openaccess-api.clevelandart.org/api/artworks/?q=<낱말1+낱말2>&cc0=1&has_image=1&limit=20
```

- `cc0=1`이 **쿼리 단계에서 라이선스를 건다**. 응답의 `share_license_status`는 `CC0`으로 온다.
- `has_image=1`로 이미지 없는 레코드를 미리 뺀다.
- 핫링크 실측 확인: `openaccess-cdn.clevelandart.org`는 특별한 헤더 없이 3400x2286 JPEG를 돌려준다.
  AIC와 달리 봇 차단이 없다.

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

## § Wellcome 1차 소스 (완전 배선)

Wellcome Collection 카탈로그. 의학·과학사 도해와 판화가 두터워 Wikimedia·CMA와 **소장품 겹침이
가장 적다.** 인증 키가 필요 없다.

```
https://api.wellcomecollection.org/catalogue/v2/works?query=<어구+어구>&items.locations.license=pdm&include=items,contributors,production&pageSize=20
```

- `items.locations.license=pdm`이 **쿼리 단계에서 라이선스를 건다**(`cc0`도 같은 방식으로 받는다).
- `include=items`가 없으면 IIIF 이미지 ID가 응답에 오지 않는다. `contributors,production`은
  작가·연도용이다.

### 배너 URL 조립

검색 응답은 직접 래스터 URL 대신 `items[*].locations[*].url`에
`https://iiif.wellcomecollection.org/image/<ID>/info.json` 형태로 IIIF 이미지 ID를 준다. 배너 URL은
여기서 조립한다:

```
https://iiif.wellcomecollection.org/image/<ID>/full/1024,/0/default.jpg
```

**폭은 1024로 고정한다.** Wellcome IIIF는 임의 폭을 서빙하지 않고 항목마다 정해진 크기 사다리만
내주며(실측: `[1024, 400, 200, 100]`), 사다리 밖 크기는 **HTTP 200 · `image/jpeg` · 0바이트**라는
조용한 형태로 실패한다. 사다리 상한은 항목의 긴 변을 1024로 맞춘 값이라, 세로로 긴 자료는 상한이
1024보다 작다(실측: 2125x3526 항목의 상한은 617).

**그래서 Wellcome의 해상도 게이트는 별도 호출이 아니라 다운로드 자체다.** § 감별 4에서 컨택트
시트를 만들려고 어차피 받으므로, **받아서 0바이트면 그 후보를 버린다.** `info.json`을 후보마다
따로 조회하면 LoC를 1차에서 내린 것과 같은 이유로 라운드트립이 샌다. 조회하지 않는다.

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

## § 감별 휴리스틱

통과 순서: **라이선스 → mime → 해상도 → 중복 배제 → 시각 판정**. 앞의 넷은 1차 소스 셋의 검색
JSON만으로 **추가 호출 없이** 판정되므로, 비싼 시각 확인(다운로드 + `Read`)은 넷을 모두 통과한
후보에만 쓴다. § 호출 레시피의 콜 2 파서가 넷을 이미 적용하니, 표에 남은 것만 눈으로 보면 된다.

### 1. 라이선스 필터

- 소스가 **PD / CC0 / 자유 라이선스(CC BY · CC BY-SA 등)로 태깅한 것만** 통과.
- 라이선스 필드가 없거나 모호하면 **제외**.
- **스킬은 저작권을 독자 판단하지 않고 소스의 태깅을 신뢰한다.** 법적 판단은 스킬의 책임 범위
  밖이고, 소스가 명시한 라이선스 태그만 근거로 삼는다. 소스별 태그 필드는 Wikimedia
  `LicenseShortName`, CMA `share_license_status`, Wellcome `locations[*].license.id`다.
- CMA와 Wellcome은 **쿼리 파라미터(`cc0=1`, `items.locations.license=pdm`)로 라이선스를 이미
  걸어** 결과를 받으므로, 파서는 필드 값을 기록용으로만 읽는다.

### 2. mime 필터

- Wikimedia는 `imageinfo[0].mime`이 `image/*`(`image/jpeg`·`image/png`·`image/webp`)인지 확인한다.
- SVG(`image/svg+xml`)·PDF·GIF는 배너로 부적합하므로 **배제**한다.
- CMA는 mime 필드가 없으므로 **URL 확장자가 `.jpg`인지로 판정**한다(`images.full`의 `.tif` 배제).
  Wellcome IIIF는 조립한 URL이 `default.jpg`라 항상 충족된다.

### 3. 해상도 게이트

폭이 **1000 미만이면 배제**한다. 배너는 노트 상단을 가로로 채우므로 저해상은 얹는 순간 뭉개진다.

- **Wikimedia** `imageinfo[0].width`, **CMA** `images.print.width`. 둘 다 검색 JSON에 이미 들어 있어
  **공짜**다. 다운로드하고 `Read`한 뒤에야 "작네" 하고 버리는 것이 시각 감별 단계에서 가장 흔한
  낭비였고, 그 왕복을 여기서 없앤다.
- **Wellcome은 예외다.** 검색 JSON에 크기가 없고 `info.json`은 후보당 추가 호출이라, 게이트를
  § 감별 4의 다운로드로 미룬다. `full/1024,`가 **0바이트로 오면 사다리 상한이 1024 미만**이라는
  뜻이므로 그 자리에서 버린다(§ Wellcome 1차 소스).

### 4. 시각 판정 (컨택트 시트 1장, `Read` 1회)

앞 단계를 통과한 후보를 **한 장씩 `Read`하지 않는다.** 6~9장을 한꺼번에 받아 **격자 컨택트 시트
하나로 합친 뒤 `Read` 한 번**으로 본다. 이 단계가 스킬 전체에서 가장 느린 곳이었고, 시트 방식이
그 지연을 후보 수만큼 나눈다.

```bash
cd <scratchpad>
# picks.txt — 콜 2 표에서 고른 후보 URL을 컨셉·소스가 섞이도록 한 줄에 하나씩
i=0
while read -r u; do i=$((i+1))
  # 시트용으로만 축소한다. Wellcome URL은 건드리지 않는다 (아래 주의)
  v=$(printf '%s' "$u" | sed -E 's#/1280px-#/500px-#; s#_print\.jpg#_web.jpg#')
  curl -sL -H 'User-Agent: banner-doc/1.0' -o "c$(printf %02d $i).jpg" "$v" &
done < picks.txt
wait
for f in c*.jpg; do [ -s "$f" ] || { echo "drop $f (0바이트)"; rm -f "$f"; }; done   # § Wellcome 해상도 게이트
montage -label '%f' c*.jpg -tile 3x -geometry 420x420+10+10 \
  -background '#1b1b1b' -fill '#eee' -pointsize 22 sheet.jpg
```

**다운로드는 병렬로 띄우고, 시트용 이미지만 축소한다.** 실측에서 후보 6장이 **8.97초·13MB에서
1.31초·2.3MB**로 줄었다. 화질 손실은 없다. `montage`가 어차피 각 칸을 420px로 줄이므로 그보다 큰
원본은 시트에서 버려지는 화소다. **배너로 기록하는 URL은 축소 전 원본 URL** 그대로다.

**Wellcome URL은 축소하지 않는다.** `full/1024,`의 0바이트 응답이 이 소스의 해상도 게이트를
겸하는데, `400,`으로 낮추면 게이트가 죽는다. 실측에서 상한이 617인 세로 항목은 `1024,`로 0바이트,
`400,`으로 108KB를 돌려줬다. 400으로 받으면 배너에는 못 쓰는 항목이 시트를 통과한다.

그다음 `sheet.jpg`를 **`Read` 한 번**으로 본다. 라벨의 `cNN.jpg`가 picks.txt의 몇 번째 줄인지로
후보를 되짚는다. 실측에서 1320x938 시트 한 장으로 계보 판화·지질 단면도·풍경 사진·고서 텍스트
페이지의 적부 판정이 모두 됐다.

- **`montage`가 없으면**(`which montage`) 후보를 한 장씩 `Read`하는 옛 방식으로 내려간다. 이걸
  위해 무엇도 설치하지 않는다.
- **후보를 담는 순서** — 컨셉당 1장씩 먼저 채워 직결형과 연상형 믹스를 보존하고, 남는 칸을 소스가
  섞이도록 메운다. 한 소스가 시트를 독점하면 반복 문제가 되돌아온다.
- 시트에서 통과가 2개 미만이면 표의 다음 후보로 **시트를 한 번 더** 만든다. 시트 재생성에도
  상한을 걸지 않는다. 상한 때문에 § 최소 확보 실패에 빠지면 전체 재검색(콜 1+2)을 부르는데, 그게
  시트 한 장보다 훨씬 비싸다.
- **볼트엔 저장하지 않는다.** 시트와 조각 이미지는 스크래치패드에만 두고 끝나면 정리한다.

아래 배제 사유는 **메타데이터로 알 수 없는 것들**이라, 여기서 탈락이 나오는 건 설계상 정상이다.

- **적합** — 고판화의 고대비·인쇄판 질감, 고지도·빈티지 도표의 선명한 선, 고전 회화의 구성.
  배너로 얹었을 때 상단에 걸쳐 읽히는 자료.
- **배제** — 문서 스캔(텍스트만 있는 페이지), 로고·엠블럼, 저해상·손상·얼룩, 워터마크 박힌
  것, 잘린 조각.
- **관련성** — 도출한 컨셉(직결/연상)에 실제로 부합하는가. 검색이 엉뚱하게 히트한 것 배제.

### 최소 확보 실패

라이선스·mime·시각을 모두 통과한 후보가 **2개 미만**이면, 임의 저품질 후보로 채우지 말고
사용자에게 **검색어 조정을 요청하고 중단**한다.
