---
title: 외부 소스를 소비하는 에이전트형 커맨드 — 전송 방식과 신뢰 경계
date: 2026-07-06
category: design-patterns
module: commands/banner-doc
problem_type: design_pattern
last_updated: 2026-07-15
applies_when:
  - "글로벌 슬래시 커맨드가 외부 웹 API·이미지를 조회하는 에이전트형일 때"
  - "소스 파생 메타데이터를 사용자 파일의 YAML 프론트매터에 기록할 때"
  - "User-Agent 등 커스텀 헤더가 필요하거나 raw JSON을 파싱해야 하는 API를 호출할 때"
  - "PreToolUse:Bash 훅(RTK 등)이 셸 명령을 재작성하는 환경에서 API 응답을 파싱할 때"
tags: [slash-command, wikimedia-api, webfetch-vs-curl, yaml-injection, frontmatter-safety, external-source-trust, rtk, transport-interception]
---

# 외부 소스를 소비하는 에이전트형 커맨드 — 전송 방식과 신뢰 경계

## Context

`~/.claude`의 기존 전역 커맨드(`/tag-doc`, `/translate-doc`)는 **세션 내 완결·외부 API 없음**이
공통 전제였다. 태그 생성·번역을 Claude가 세션에서 직접 수행하고, 파일에 쓰는 값은 전부
**자기생성 신뢰값**이었다.

`/banner-doc`은 이 계열에서 처음으로 **웹 검색·이미지 조회(외부 네트워크)를 동반하는 에이전트형
커맨드**다. Wikimedia Commons API에서 이미지 URL·라이선스·작가를 받아 노트 프론트매터에 기록한다.
이 한 가지 차이 — 외부 소스를 소비한다 — 가 자기완결형 커맨드에는 없던 **세 가지** 설계 요건을
만든다.

앞의 두 요건(§1·§2)은 계획·구현 단계에서 실제 호출/시뮬레이션으로 검증됐다. **§3은 실전 실행에서
뒤늦게 드러났다** — 계획 단계의 검증은 "curl을 쓰면 raw JSON이 온다"를 전제했는데, 실제 세션에는
`curl`을 재작성하는 `PreToolUse:Bash` 훅이 있어 그 전제가 성립하지 않았다. §1을 지켰는데도 파싱이
깨진 것이 §3을 발견한 경위다.

## Guidance

### 1. 헤더·raw JSON이 필요한 API 호출은 `WebFetch`가 아니라 `Bash` curl로

커스텀 헤더가 필수이거나 응답을 raw JSON으로 파싱해야 하는 외부 API는 **`Bash` curl에
`-H` 헤더를 붙여** 호출한다. `WebFetch`는:

- **커스텀 헤더를 설정할 수 없다** — Wikimedia는 `User-Agent`가 없으면 403을 반환한다.
- **raw JSON을 반환하지 못한다** — `extmetadata` 같은 구조를 파싱할 수 없다.

`WebSearch`/`WebFetch`는 **보조 소스 탐색·페이지 조회**에만 남기고, 1차 API 호출에는 쓰지 않는다.

**단 이것은 필요조건일 뿐 충분조건이 아니다** — curl로 바꿔도 로컬 훅이 응답을 변조할 수 있다(§3).

### 2. 소스 파생 값을 사용자 파일에 쓸 때는 신뢰 경계를 친다

외부 소스에서 온 값은 **신뢰 불가**다. YAML 프론트매터에 기록하기 전 세 단계를 거친다:

1. **HTML 평문화** — 예: Wikimedia `extmetadata.Artist.value`는 실제로
   `<bdi><a href="…">이름</a></bdi>` HTML로 온다(라이브 호출로 확인). 태그를 제거해 평문만 남긴다.
2. **개행·제어문자 제거**.
3. **YAML 문자열로 인용/이스케이프** — 큰따옴표로 감싸고 내부 `"`·`\`를 이스케이프한다.

**HTML 제거만으로는 부족하다.** 평문화해도 YAML 구조 메타문자(`:`·선두 `-`·`#`·`|`·`"`)가
남으므로, 이스케이프 없이 기록하면 악의적 소스 메타데이터가 프론트매터를 손상시키거나 외부 키를
주입할 수 있다. URL을 포함한 **모든** 소스 파생 스칼라에 적용한다.

### 3. 전송 계층은 로컬 훅에도 변조된다 — stdout을 신뢰하지 말고 `-o <file>`로 받는다

§1·§2는 **외부 소스**를 신뢰 불가로 다뤘다. §3은 방향이 반대다: **로컬 환경이 응답을 변조한다.**

이 환경에는 `PreToolUse:Bash` 훅(`~/.claude/hooks/rtk-rewrite.sh`)이 있어 `curl …`을
**`rtk curl …`로 자동 재작성**한다(파이프·리다이렉트 유무와 무관). `rtk`는 토큰 최적화기라
`rtk curl`은 **응답 본문 대신 "스키마 개요"를 stdout에 출력**한다. 그래서 `curl`을 썼는데도
파서에 JSON이 오지 않는다.

**변조는 stdout 경로에서만 일어난다.** `-o <file>`은 stdout을 거치지 않아 훅이 가로챌 것이
없으므로 파일에는 원본 응답 바이트가 그대로 떨어진다. 실측 비교:

| 형태 | 파서가 실제로 받는 것 |
|---|---|
| `curl … -o out.json` | **원본 JSON** ✅ |
| `curl … > out.json` (셸 리다이렉트) | 스키마 개요 ❌ — **조용히** 잘못된다 |
| `curl … \| python3` | 스키마 개요 ❌ → `JSONDecodeError` |
| `rtk proxy curl … -o out.json` | 원본 JSON ✅ (문서화된 명시적 우회) |

**"파이프가 문제"가 아니라 "stdout이 문제"다.** 이 구분이 실질적인 이유: 파이프를 리다이렉트로
바꾸는 "수정"은 증상만 조용하게 만들어 더 나쁘다 — 에러 없이 스키마 파일이 저장되고, 한참 뒤
파싱에서야 터져 원인이 멀어진다.

**훅을 끄는 것은 답이 아니다.** `-o`가 이미 우회하고, 평범한 `curl -o`는 훅·rtk가 없는 환경에서도
그대로 동작한다(훅은 rtk 부재 시 경고 후 통과시킨다). `rtk proxy`는 rtk 설치를 전제하므로 오히려
이식성이 낮다. 훅은 전역 `matcher: Bash`라 커맨드 단위 off 스위치도 없다.

## Why This Matters

`tag-doc`은 이 방어가 **불필요**했다 — 쓰는 값이 자기생성 신뢰값이었기 때문이다. 정확히 그
이유로, 자기완결형 커맨드의 프론트매터 병합 패턴을 외부 소스 커맨드에 그대로 미러하면 조용한
취약점이 생긴다. **신뢰 경계는 "값이 어디서 왔는가"에 따라 갈리지, 파일에 쓰는 메커니즘(제자리
편집)이 같다고 해서 방어까지 같아지는 게 아니다.**

전송 방식도 같은 함정이다. 세션 내 완결형에는 네트워크 호출이 없으니 "웹에서 뭔가 가져온다"를
자동으로 `WebFetch`로 떠올리기 쉬운데, 헤더 필수·raw JSON 요건을 `WebFetch`가 만족 못 하므로
403·파싱 실패로 조용히 깨진다.

### 옳은 처방 + 틀린 이유 = 가장 위험한 상태 (§3의 메타 교훈)

§3이 드러난 경위 자체가 교훈이다. `-o <file>`이라는 **옳은 처방을 이미 쓰고 있었지만**, 문서에
적힌 이유는 "파이프가 문제"라는 **틀린 진단**이었다. 이 조합이 왜 최악인가:

- 처방이 우연히 맞으니 **아무도 의심하지 않는다.** 동작하는 코드는 검증 압력을 받지 않는다.
- 틀린 이유는 **틀린 일반화를 낳는다.** "파이프가 문제"를 믿으면 리다이렉트(`> file`)는 안전하다고
  추론하게 되는데, 실제로는 그게 조용히 깨지는 경로다. 즉 문서가 미래의 자신을 함정으로 민다.
- 증상만 보고 원인을 지목한 것이 화근이었다. `FAILED: curl` + exit 1을 보고 "훅이 파이프에
  개입"이라 **추측**했고, 그 추측을 검증 없이 문서에 사실로 기록했다.

**교훈**: 동작하는 처방이라도 그 *이유*를 문서에 박기 전에 검증한다. 특히 "왜 이게 되는가"를
추측으로 채우면, 그 문서는 지식이 아니라 **미래의 오류 생성기**가 된다. 검증은 싸다 — 이번엔
`rtk rewrite`에 명령을 넣어보고 `-o`/리다이렉트/파이프를 각각 돌려 파싱해보는 Bash 2콜이 전부였다.

## When to Apply

- 전역/프로젝트 슬래시 커맨드가 외부 API·이미지를 조회하는 에이전트형일 때.
- 커스텀 헤더(User-Agent·인증 등)나 raw JSON 파싱이 필요한 API를 부를 때 → `Bash` curl.
- 외부에서 받은 값을 사용자 파일(프론트매터·설정 등)에 기록할 때 → HTML 평문화 → 개행/제어문자
  제거 → YAML 이스케이프.
- 자기완결형 커맨드의 in-place 편집 패턴을 외부 소스 커맨드로 미러할 때 — 신뢰 경계 방어를
  추가로 넣었는지 점검.
- **셸 명령을 재작성하는 `PreToolUse:Bash` 훅이 있는 환경에서 API 응답을 파싱할 때** → stdout을
  신뢰하지 말고 `-o <file>`로 받은 뒤 별도 단계에서 파싱.
- 처방은 동작하는데 **그 이유를 검증한 적이 없을 때** → 문서에 사실로 박기 전에 재현으로 확인.

## Examples

**전송 — 검증된 curl 호출(Wikimedia Commons):**

`-o <file>`이 **필수**다(§3). stdout으로 받으면 훅이 재작성한 `rtk curl`이 스키마 개요를 뱉는다.

```bash
# 콜 1 — 파일로 받는다 (stdout을 거치지 않으므로 훅이 가로챌 것이 없다)
curl -s -H 'User-Agent: banner-doc/1.0 (Claude Code; contact via user)' \
  'https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrsearch=celestial%20map%20engraving&gsrnamespace=6&prop=imageinfo&iiprop=url%7Cextmetadata%7Cmime%7Csize&iiurlwidth=1200&format=json' \
  -o wm_chart.json

# 콜 2 — 별도 단계에서 파싱 (curl | python 파이프는 스키마 개요를 먹어 JSONDecodeError)
python3 -c "import json; d=json.load(open('wm_chart.json')); print(len(d['query']['pages']))"
```

라이브 응답에서 `thumburl`, `mime: image/jpeg`, `extmetadata.LicenseShortName: Public domain`,
`extmetadata.Artist: <bdi><a …>` 확인 — 필드매핑 표가 JSON 실재와 일치.

**전송 변조 — 훅 개입을 재현으로 확인하는 법:**

```bash
# 훅이 무엇으로 재작성하는지 직접 확인 (파이프 유무와 무관하게 rtk curl로 바뀐다)
rtk rewrite 'curl -s https://example.com'        # → rtk curl -s https://example.com

# 같은 URL을 -o / 리다이렉트로 각각 받아 파싱 비교
rtk curl -s "$U" -o a.json    # → 원본 JSON      ✅
rtk curl -s "$U" >  b.json    # → 스키마 개요    ❌ (조용히 잘못됨)
```

**신뢰 경계 — 주입 시도가 무력화되는 과정:**

```
# 악의적 소스 메타데이터 (개행 + YAML 메타문자 + 키주입 시도)
banner_creator (raw): <bdi><a href="#">Evil: Name</a></bdi>\ninjected_key: pwned

# HTML 평문화 → 개행 제거 → YAML 이스케이프 적용 후
banner_creator: "Evil: Name injected_key: pwned"
```

결과 프론트매터는 유효 YAML로 파싱되고, `banner*` 6키만 존재하며, `injected_key` 같은 외부 키가
주입되지 않고, 개행도 잔존하지 않는다(주입 시뮬레이션으로 확인).

## Related
- `commands/banner-doc.md` (Hard rules: RTK 규약·네트워크 규약·쓰기 안전), `banner-doc-assets/search-and-vetting.md` (§ RTK 상호작용·§ 호출 레시피·§ Wikimedia 완전 배선·쓰기 안전)
- `~/.claude/hooks/rtk-rewrite.sh` — `curl` → `rtk curl` 재작성의 실체. `settings.json`의 `PreToolUse` matcher `Bash`에 등록돼 전역 적용
- 대비 선례: `commands/tag-doc.md` — 자기생성 신뢰값이라 신뢰 경계 방어가 불필요했던 자기완결형 커맨드
- §3은 2026-07-15 실행에서 발견돼 `refactor: banner-doc 검색을 Bash 2콜로 축약하고 RTK 전송 규약 정정` 커밋으로 두 문서에 반영됨
