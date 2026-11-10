---
description: Find Unsplash photos that fit a note, let the user pick one of three, and record it into the note's Pixel Banner frontmatter in place
argument-hint: <input_file>
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion
---

# add-banner-from-unsplash

Obsidian 노트를 읽어 그 글의 주제와 결에 맞는 **Unsplash 무료 사진** 후보 3개를 찾아 제시하고,
사용자가 고르면 그 사진의 **원격 URL + 출처 메타**를 노트의 Pixel Banner 프론트매터에 **제자리
기록**한다.

형제 커맨드 `/banner-doc`과 같은 흐름이고 출력 필드도 같은 6개 `banner*`라서 두 커맨드는 서로의
결과를 덮어쓸 수 있다. 차이는 소스다. `/banner-doc`이 공개 도메인 역사 자료를 찾는 반면 이 커맨드는
**Unsplash 공식 API**로 현대 사진을 찾고, 라이선스 판정 대신 **Unsplash API 약관**(핫링크, 다운로드
트래킹, 작가 표기)을 지킨다. Pixel Banner의 **"URL 이미지 허용" 설정이 켜져 있다고 전제**하고 설정은
바꾸지 않는다.

## Arguments

User input: `$ARGUMENTS`

- 첫 번째 위치 인자 = **입력 파일 경로**(필수). 없거나 경로가 존재하지 않으면 중단하고 무엇이
  빠졌는지 알린다.

## 전제: 환경 변수 두 개

| 변수 | 내용 |
|---|---|
| `UNSPLASH_ACCESS_KEY` | unsplash.com/developers 에서 만든 앱의 Access Key |
| `UNSPLASH_APP_NAME` | 같은 앱의 이름. 작가 표기 링크의 `utm_source` 값으로 쓴다 |

Step 1에서 `[ -n "$VAR" ]`로 존재만 확인한다. 하나라도 비어 있으면 **중단**하고, 사용자에게 셸
프로필(`~/.zshenv` 등)에 `export`하라고 안내한다. 키 값은 출력하지도, 어떤 파일에 쓰지도 않는다.
`settings.json`은 git으로 추적되므로 키를 넣을 자리가 아니다.

## Workflow

### Step 1: 로드와 핵심 주제 파악

1. 입력 노트를 `Read`로 읽고, 같은 턴에 환경 변수 두 개의 존재를 확인한다.
2. **핵심 주제는 본문에서 정한다.** 제목은 은유적이거나 넓거나 낚시성이어서 글이 실제로 다루는 대상과
   어긋나기 쉽다. 본문 전체를 읽고 아래 순서로 판단한다.
   - 글이 **가장 많은 분량을 들여 설명하거나 주장하는 대상**이 무엇인지 찾는다. 도입부의 일화나 예시,
     곁가지 비교 대상은 핵심 주제가 아니다.
   - 그 대상을 **한국어 한 문장**으로 적는다(예: "LLM 에이전트가 긴 작업에서 컨텍스트를 잃는 문제와
     그 압축 전략"). 이 문장이 Step 2 컨셉의 유일한 출발점이다.
   - 본문에서 핵심 주제를 받치는 **구체 재료**를 함께 건진다: 고유 명사, 장소, 사물, 되풀이되는 은유와
     정서. 연상형 컨셉은 이 재료에서 나온다.
3. **제목은 대조용 힌트로만 쓴다.** 프론트매터 `title` → 파일명(확장자를 떼고 구분자를 공백으로) → 본문
   첫 H1 순서로 찾아서 핵심 주제 문장과 비교한다. 둘이 어긋나면 본문을 따른다. 본문이 거의 없는
   노트(몇 줄짜리 메모)일 때만 제목을 핵심 주제로 삼는다.

### Step 2: 비주얼 컨셉 3갈래

Step 1의 **핵심 주제 문장**에서 출발해 **직결형 1개 이상 + 연상형 1~2개**, 총 3개 컨셉을 만들고 컨셉당
**영어 검색어 1개**를 고른다. 제목의 단어를 그대로 영어로 옮긴 검색어는 쓰지 않는다. 각 검색어가 핵심
주제의 어느 측면을 찍는지 한 줄로 댈 수 없으면 버리고 다시 짠다.
Unsplash는 사진 저장소이므로 검색어는 **피사체, 장면, 빛, 질감**으로 짠다. 판화나 매체 용어는 쓰지
않는다.

- **직결형**: 주제를 문자 그대로 찍은 사진. "증기기관" → `steam locomotive`, "천문학" →
  `night sky milky way`.
- **연상형**: 글의 결을 환기하는 사진. "분산 시스템" → `city lights aerial night`(노드와 연결망),
  "기억과 누적" → `rock strata layers`, "집중과 몰입" → `minimal desk morning light`.
- 검색어는 2~4단어가 적당하다. 길어지면 결과가 줄고, 한 단어면 너무 흔한 사진이 상위를 차지한다.
- 배너는 가로로 길게 잘리므로 **피사체가 화면 전체에 퍼진 장면**(풍경, 패턴, 질감)이 인물 클로즈업보다
  잘 맞는다. 컨셉을 고를 때 이 점을 반영한다.

### Step 3: 검색과 파싱 (Bash 1콜)

아래 스크립트를 스크래치패드에서 **한 번의 Bash**로 실행한다. 3개 검색을 `&`로 병렬로 띄우고,
볼트의 기존 배너를 모으고, 파싱까지 끝낸다. raw JSON은 파일로만 받고 stdout에는 **컴팩트 표만**
낸다. 볼트 루트는 입력 파일에서 위로 거슬러 올라가며 `.obsidian/`을 찾아 정한다.

```bash
cd <scratchpad>
H1="Authorization: Client-ID $UNSPLASH_ACCESS_KEY"; H2='Accept-Version: v1'
# 한 줄에 "<컨셉명> <검색어>". 검색어의 공백은 +. direct = 직결형, assoc* = 연상형
while read -r name q; do
  curl -s -H "$H1" -H "$H2" -o "us_${name}.json" \
    "https://api.unsplash.com/search/photos?query=${q}&per_page=20&orientation=landscape&content_filter=high" &
done <<'Q'
direct steam+locomotive
assoc1 city+lights+aerial+night
assoc2 rock+strata+layers
Q
grep -rhoE '^banner:[[:space:]]*.*' "$VAULT" --include='*.md' > used_banners.txt 2>/dev/null || : > used_banners.txt
wait
APP="$UNSPLASH_APP_NAME" python3 - <<'EOF'
import json, glob, os, re
app = os.environ["APP"]
KEY = re.compile(r'photo-[0-9]+-[0-9a-f]+')
seen = set(KEY.findall(open("used_banners.txt").read()))   # 볼트 배제
clean = lambda s: re.sub(r'[\x00-\x1f\x7f]', ' ', s or '').strip()
cols = {}
for f in sorted(glob.glob("us_*.json")):
    concept = f[3:-5]
    d = json.load(open(f))
    if "errors" in d:
        print(f"! {concept}: {d['errors']}"); continue
    rows = []
    for r in d.get("results", []):
        raw = r["urls"]["raw"]
        if r.get("premium") or r.get("plus") or "plus.unsplash.com" in raw:
            continue                                         # Unsplash+ 배제
        if r["width"] < 2000:
            continue                                         # 해상도 게이트
        m = KEY.search(raw)
        k = m.group(0) if m else r["id"]
        if k in seen:
            continue                                         # 볼트·실행 내 중복 배제
        seen.add(k)
        sep = "&" if "?" in raw else "?"
        rows.append(dict(
            concept=concept, key=k, size=f'{r["width"]}x{r["height"]}',
            banner=f"{raw}{sep}w=2000&fit=crop&q=80&fm=jpg",
            source=f'{r["links"]["html"]}?utm_source={app}&utm_medium=referral',
            creator=clean(r["user"]["name"]),
            title=clean(r.get("description") or r.get("alt_description") or ""),
            year=(r.get("created_at") or "")[:4],
            small=r["urls"]["small"], dl=r["links"]["download_location"]))
        if len(rows) == 4:
            break                                            # 관련도 상위 밴드
    cols[concept] = rows
out = [x for t in zip(*[c + [None] * (4 - len(c)) for c in cols.values()]) for x in t if x][:9]
json.dump(out, open("cands.json", "w"), ensure_ascii=False, indent=1)
with open("picks.txt", "w") as p:
    for i, c in enumerate(out, 1):
        p.write(c["small"] + "\n")
        print(f'c{i:02d} | {c["concept"]} | {c["size"]} | {c["creator"]} | {c["title"][:60]}')
EOF
```

- 예시 검색어는 자리표시다. 실제 값은 Step 2의 컨셉으로 바꾼다.
- 표의 `cNN`은 `cands.json`의 순번이고 `banner*` 6필드와 `dl`이 모두 거기 있다. **선택 뒤 재검색이나
  재파싱은 하지 않는다.**
- `! <concept>: …` 줄은 API 오류다. `401`은 키 문제이므로 중단하고 알린다. 빈 결과가 나온 컨셉은
  버리고 나머지로 진행한다.
- 응답이 `403 Rate Limit Exceeded`면 데모 앱의 시간당 50회 한도에 걸린 것이므로 중단하고 알린다.

### Step 4: 감별 (Bash 1콜 + 컨택트 시트 `Read` 1회)

```bash
cd <scratchpad>
i=0; while read -r u; do i=$((i+1)); curl -sL -o "c$(printf %02d $i).jpg" "$u" & done < picks.txt; wait
for f in c*.jpg; do [ -s "$f" ] || rm -f "$f"; done
montage -label '%f' c*.jpg -tile 3x -geometry 420x280+10+10 \
  -background '#1b1b1b' -fill '#eee' -pointsize 22 sheet.jpg
```

`urls.small`은 표시용 썸네일이라 다운로드 트래킹 대상이 아니다. `sheet.jpg`를 `Read` 한 번으로 보고
**최종 3개**를 고른다. `montage`가 없으면 후보를 한 장씩 `Read`한다. 그 때문에 무엇도 설치하지 않는다.

- **고른다**: 가로로 잘라도 읽히는 구도, 화면 전체에 퍼진 피사체, 핵심 주제와의 실제 부합.
- **뺀다**: 중앙의 작은 피사체(잘리면 사라진다), 인물 얼굴 클로즈업, 글자나 로고가 큰 사진, 검색이
  엉뚱하게 히트한 사진.
- 3개를 고를 때 **컨셉이 섞이게** 한다. 한 컨셉이 셋을 모두 차지하면 선택지가 사실상 하나가 된다.
- 최종 3개 가운데 **추천 1개**를 정한다. 기준은 핵심 주제를 가장 직접 환기하는지가 먼저이고, 배너
  구도(가로 크롭 내성)가 그다음이다. 추천 이유는 Step 5에서 쓸 수 있도록 한 줄로 적어 둔다.
- 통과가 3개 미만이면 Step 2로 돌아가 부족한 컨셉의 검색어를 바꿔 한 번 더 돌린다. 그래도 2개
  미만이면 임의 후보로 채우지 않고 사용자에게 검색어 방향을 묻고 중단한다.

### Step 5: 제시와 선택 (`AskUserQuestion`)

1. 노트에 이미 `banner`가 있으면 제시 전에 **현재 배너 URL을 먼저 알린다.**
2. `question` 본문에 Step 1의 **핵심 주제 문장**을 함께 적는다. 사용자가 모델이 글을 어떻게 읽었는지
   확인하고, 어긋났으면 Other로 바로잡을 수 있게 하기 위해서다.
3. 각 후보 옵션:
   - `label`: 소재를 담은 짧은 제목(예: "안개 낀 산맥 능선").
   - `description`: 미리보기 URL(`banner` 값), 작가, 해상도, 이 글에 맞는 이유 한 줄.
   - **추천 후보**는 옵션 목록의 **첫 번째**에 두고 `label` 끝에 ` (추천)`을 붙인다. `description`의
     이유 한 줄은 다른 후보보다 왜 나은지를 적는다. 추천은 정확히 1개다.
4. 옵션 구성은 상한 4개 안에서 후보 3개를 모두 지킨다.
   - `banner` **없음** → 후보 3개 + "다 별로 → 재검색".
   - `banner` **있음** → 후보 3개 + "현재 배너 유지". 재검색은 자동으로 붙는 "Other"로 받는다.
5. 분기: "현재 배너 유지" → 아무것도 바꾸지 않고 종료. "재검색" 또는 Other 입력 → 사용자 의견을 반영해
   Step 2로. 의견이 핵심 주제 자체를 바로잡는 내용이면 Step 1의 주제 문장부터 고친다. 후보 선택 →
   Step 6.

### Step 6: 다운로드 트래킹과 적용

1. **다운로드 트래킹 (Bash 1콜, 약관 필수)**: 선택한 후보의 `dl`을 같은 인증 헤더로 GET한다. 응답
   본문은 버린다. 실패해도 적용은 진행하고 리포트에 실패를 적는다.
   ```bash
   curl -s -o /dev/null -w '%{http_code}\n' -H "Authorization: Client-ID $UNSPLASH_ACCESS_KEY" \
     -H 'Accept-Version: v1' "<dl>"
   ```
2. **프론트매터 기록**: `cands.json`의 값으로 6필드를 쓴다.

   | 필드 | 값 |
   |---|---|
   | `banner` | `banner` (raw URL + imgix 파라미터. `ixid`를 보존한 핫링크) |
   | `banner_source` | `source` (사진 페이지 + `utm_source`/`utm_medium`) |
   | `banner_license` | `"Unsplash License"` |
   | `banner_title` | `title`. 비어 있으면 빈 문자열로 두고 지어내지 않는다 |
   | `banner_creator` | `creator` (작가 실명) |
   | `banner_year` | `year`. **업로드 연도**이며 촬영 연도가 아니다 |

3. **쓰기 안전**: API 값은 신뢰할 수 없으므로 6필드 전부를 **큰따옴표 YAML 문자열**로 쓰고 내부
   `"`와 `\`를 이스케이프한다. 제어문자는 파서가 이미 지웠다.
4. **프론트매터 3-케이스**:
   - 있고 `banner*` 있음 → `banner*`만 덮어쓴다.
   - 있고 `banner*` 없음 → `banner*`만 끝에 추가한다. 다른 필드의 순서와 값을 보존한다.
   - 없음 → `banner*`만 담은 최소 블록을 만든다. `title` 등은 지어내지 않는다.
5. **본문은 바이트 단위로 보존한다.** `Edit`(병합) 또는 `Write`(새 블록)로 입력 파일 자체를 고친다.
   사본과 백업은 만들지 않는다.
6. 스크래치패드의 `us_*.json`, `c*.jpg`, `sheet.jpg`를 지운다. 볼트에는 처음부터 아무 이미지도
   저장하지 않는다.

### Step 7: 리포트

간결 블록 하나만 출력한다. 문서 본문은 출력하지 않는다.

```
✓ Banner (Unsplash) → <input_path>
  · 핵심 주제: <Step 1의 한 문장>
  · 선택: <title 또는 소재> / Photo by <creator> on Unsplash (<추천 채택|추천 외 선택>)
  · 출처: <banner_source>
  · 다운로드 트래킹: <200|실패 코드>
  · banner 필드: <created|overwritten|added>
  · 전제: Pixel Banner "URL 이미지 허용" 설정 필요
```

## Hard rules

- **무료 사진만**: Unsplash+(`premium`/`plus` 플래그 또는 `plus.unsplash.com` 호스트)는 파서에서
  배제한다.
- **핫링크 전용**: 배너는 API가 준 `urls.raw`에 imgix 파라미터만 덧붙인 URL로 건다. 이미지를 볼트나
  다른 호스트에 다시 올리지 않는다.
- **다운로드 트래킹**: 사용자가 고른 사진에 한해 `download_location`을 정확히 한 번 호출한다. 감별용
  썸네일 조회는 트래킹하지 않는다.
- **작가 표기**: `banner_creator`는 작가 실명, `banner_source`는 `utm_source=<UNSPLASH_APP_NAME>&
  utm_medium=referral`이 붙은 사진 페이지 URL이다.
- **키 보호**: Access Key는 `Authorization` 헤더로만 보낸다. 쿼리 문자열, 출력, 파일 어디에도 쓰지
  않는다.
- **라운드트립 예산**: 검색·파싱 1콜 + 시트 1콜 + 트래킹 1콜 = **Bash 3콜**, 시각 감별 `Read` 1회.
  검색은 실행당 3요청이라 데모 한도(시간당 50회) 안에서 충분히 여러 번 돌릴 수 있다.
- **중복 배제**: 볼트가 이미 쓴 사진과 한 실행 안에서 이미 나온 사진을 뺀다. 키는 URL 문자열이 아니라
  `images.unsplash.com` 경로의 `photo-<숫자>-<해시>` 조각이다.
- **본문 불변과 멱등성**: `banner*` 6필드만 쓴다. 재실행은 정상 동작이며 기존 배너가 있으면 "현재
  배너 유지"를 제공한다.
