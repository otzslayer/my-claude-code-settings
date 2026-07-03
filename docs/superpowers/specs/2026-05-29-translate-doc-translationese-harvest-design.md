# translate-doc ← im-not-ai 번역투 패턴 흡수 설계

- **작성일**: 2026-05-29
- **상태**: 설계 (사용자 검토 대기)
- **대상 스킬**: `~/.claude/commands/translate-doc.md` + `~/.claude/translate-doc-assets/`
- **출처 스킬**: [im-not-ai / humanize-korean](https://github.com/epoko77-ai/im-not-ai) v2.0 (pin `807172` · 2026-05-07)

---

## 1. 배경과 문제

사용자는 `/translate-doc`(영어 마크다운 → 자연스러운 한국어 번역)으로 작업 중이며 현재 결과에 만족한다. 별도로 발견한 `im-not-ai`(humanize-korean) 스킬을 번역 워크플로우에 **추가로 활용할 수 있는지** 검토가 목적이다.

`im-not-ai`는 "AI(ChatGPT·Claude·Gemini)가 쓴 한글 글을 의미는 한 글자도 건드리지 않고 문체·리듬·표현만 자연스럽게 윤문"하는 스킬이다. 입력 정의("AI가 쓴 한글")가 `translate-doc`의 출력물("Claude가 쓴 한글 번역문")과 정확히 일치해, 후처리 단계로 연결하려는 유혹이 강하다.

## 2. 검토 결론 (핵심 의사결정)

후처리 파이프라인(`translate-doc` → `humanize`)은 **채택하지 않는다.** 대신 im-not-ai의 분류 체계(taxonomy)에서 **번역투 특화 패턴만 골라 translate-doc의 Step 5 자기검토에 흡수**한다.

파이프라인을 버리고 흡수를 택한 이유:

1. **source-access 우위 (적극적 이유).** translate-doc은 **영어 원문을 본다.** 무생물 주어(A-15), 영어 대명사 직역(A-16), 긴 좌향 관형구(A-18) 같은 패턴은 원문과 대조하며 고칠 때 가장 정확하다. im-not-ai는 한글만 보는 **source-blind** 후처리라, 같은 패턴을 다뤄도 원문 근거 없이 추정해야 한다. 흡수는 이 우위를 살리고, 파이프라인은 버린다.
2. **source-blindness 위험 회피.** im-not-ai의 의미 불변 가드(변경률 30%/50%)는 "한글 입력 대비"로만 작동한다. 번역 단계 오역이나 윤문 중 생긴 의미 드리프트를 영어 원문과 대조하지 못한다. 번역 워크플로우에서 fidelity가 최우선인데, 후처리는 이를 약화시킨다.
3. **구조 보존 철칙과 충돌.** im-not-ai 처방 상당수(헤딩 제거, 불릿→산문, 이모지 삭제, 숫자 인덱싱 제거)는 마크다운 구조를 바꾼다. translate-doc은 정반대로 "원문 구조 100% 보존"이 하드룰이다. 사용자는 기술 문서와 에세이를 **둘 다** 번역하므로, 기술 문서의 의미 있는 구조를 "AI 티"로 오인해 파괴할 위험이 실재한다.
4. **중복.** im-not-ai 가치의 절반 이상(번역투 A-1·A-2, 피동 A-8·A-9, `~할 수 있다` A-10, 리듬 E-1, 종결어미 다양화)은 translate-doc의 Step 5 14항 + system_prompt "Patterns to Eliminate" 표가 이미 강하게 커버한다.
5. **배포 형태.** im-not-ai는 별도 repo clone + `_workspace/` 생성 + 5인/monolith 에이전트 + 자체 run_id 관리를 요구한다. 글로벌 슬래시 커맨드 단일 세션인 translate-doc과 운영 모델이 다르다.

## 3. 완전성 검증 (사용자 요청: taxonomy + playbook + scholarship 전수)

세 파일을 모두 읽어 확인:

- `ai-tell-taxonomy.md` (588줄, 10대 카테고리 × 50+ 서브패턴) — 상위집합.
- `rewriting-playbook.md` — 카테고리별 치환 레시피.
- `scholarship.md` — 학술 근거 SSOT. **새 패턴 0건** (8유형 T1~T8·15항목 PE1~PE15 전부 taxonomy ID에 1:1 매핑). 단 두 가지 건짐:
  - **처방 verbatim 예시**: 이중피동 `잊혀지다→잊히다`, light verb `회의를 가지다`·GPT 실출력 `에너지 공급을 가진다`, 명사화 `the implementation of the policy → 정책 시행`. 흡수 규칙에 구체 예시로 포함.
  - **PE15 호칭 직역** (`Mr./Ms./Dr.` → 선생님·박사님 또는 생략). translate-doc은 인명 음차만 다루고 직함 호칭은 명시가 없어 **신규 흡수 후보**.
  - **caveat가 제외 판단을 뒷받침**: C5(단순 `~의` 제외), C3(post-editese metric speculative), C1(경어법 estimated) — 본 설계의 제외 결정과 일치.

## 4. 흡수 분류 전체 (review-all, add-subset)

사용자 요청대로 **전체를 분류**하되, 실제 추가는 Tier 1 + 고가치 Tier 2로 한정한다.

### 4.1 ✅ 추가 — Tier 1 (Step 5 완전 부재 · 번역투 핵심 · 구조 비파괴)

| ID | 패턴 | 처방 요지 | 적용 위치 |
|---|---|---|---|
| C-11 | 연결어미 뒤 쉼표 (`-고,` `-지만,` `-면서,`) — 영어 comma-after-conjunction 이식. 최강 단일 지표(4.84배) | 연결어미 뒤 쉼표 일괄 제거 | Step 4 (문장) |
| A-7 | light verb (`have/make/take/give + N`): `회의를 가지다`·`결정을 만들다` | 동사 환원(`회의를 했다`) 또는 이중주어 | Step 4 (문장) |
| A-15 | 무생물·추상 주어 + 만능동사 (`The X shows/provides/brings`) | 행위자 주어로 환원, 또는 `X로 인해/에 따르면` 분리 | Step 4 (문장) |
| A-18 | 긴 좌향 수식 관형구 (영어 관계절 직역, 명사 앞 3어절+) | 문장 분리 또는 후치 동격절(`X를 만났는데, 그 X는…`) | Step 4 (문장) |
| A-16 | 영어 대명사 직역 (`he/she/it/they → 그/그녀/그것/그들`), 단락 3회+ | 50~70% 영형(생략)·명사구·호칭. (Step 5 #9 보강) | Step 5 (density) |
| PE15 | 호칭 직역 (`Mr./Ms./Dr.`) | 한국어 호칭(선생님·박사님·과장님) 또는 생략 | Step 4 (문장) |

### 4.2 ✅ 추가 — Tier 2 고가치 (Step 5 약함/부재)

| ID | 패턴 | 처방 요지 | 적용 위치 |
|---|---|---|---|
| A-19 | 이중 조사 (`~에서의`/`~으로의`/`~에의`/`~으로부터의`). **단순 `~의`는 제외(caveat C5)** | 절·구로 풀어쓰기 | Step 5 (density 3회+) |
| E-2 | 진행형 `~고 있다` 자동 매핑 (영어 be-ing 직역) | 단순 시제 환원 검토(`읽고 있다→읽는다`) | Step 4 (문장) |
| F-4 | 영어 명사화 `-tion/-ment/-ness/-ity` 한국어 명사 직역 | 동사·형용사 어근 환원(`정책 시행`) | Step 4 (문장) |
| G-1/G-2 | hedging 남발 (`~로 보인다`/`~인 듯하다`/이중완곡) | 단언 가능 지점은 단언, 완곡은 진짜 불확실한 곳만 | Step 5 (density) |
| H-3 | 메타 진입 (`이는~`/`이 점에서`/`이 관점에서`) 3회+ | 앞 문장과 붙이거나 본 서술로 직진 | Step 5 (density 3회+) |
| A-3~A-6·A-11·A-13 | 조사 직결 확장 (`~에 있어서`·`~라는 점에서`·`~와 관련하여`·`~에 기반하여`·`~을 위해`·명사나열) | 목적격/주제 조사로 직결 (표면 교정형, 묶음 1항) | Step 4 (문장) |

### 4.3 ⚪ 이미 커버 (흡수 불필요)

`A-1`(~에 대해) `A-2`(~를 통해) `A-8`(~되어지다) `A-9`(~에 의해) `A-10`(~할 수 있다) `A-12`(이루어지다/만들어지다) `A-14`(그리고 문두) `B-1`(괄호병기) `B-2`(영어용어) `B-3`(영어 인용구) `E-1`(리듬 균일) `E-4`(단문 일변도) `F-5`(~적 N) `H-1`(문두접속사) `I-1`(것이다) `I-3`(~라는 것) `J-3`(em dash) — Step 5 14항 + system_prompt 표/섹션에 이미 존재(active voice·전환어·리듬 combine·영어 인용 처리 등).

### 4.4 ❌ 제외

- **구조 충돌** (원문 구조 100% 보존 철칙 위반): `C-1` `C-2` `C-3` `C-4` `C-5` `C-6` `C-9` `C-10` `E-3` `J-1` `J-2` `J-4` (병렬/불릿/헤딩/문단요약공식/이모지/인덱싱/콜론헤딩/문단길이/볼드/따옴표/괄호부연).
- **원문 충실성**: `D-1~D-7` (결산 lexicon·hype·결말공식·변환공식). 번역은 원문을 따라가므로 원문에 있으면 살린다. 번역가가 새로 만든 상투구는 Step 5가 이미 처리.
- **정량 metric** (LLM 자가측정 신뢰도 낮음 + caveat C3 speculative): `C-12`(쉼표 포함률) `E-5`(쉼표 분절 길이) `E-6`(POS 다양성) post-editese 3축.
- **장르/맥락 불일치**: `E-7`(청자 경어법 — 번역 본문은 `~한다` declarative 고정, caveat C1 estimated) `A-17`(upstream도 hold) `G-3`(정책·보고서 한정).

### 4.5 🕓 보류 (deferred — 약함/맥락의존, 재평가 가능)

흡수도 제외도 아닌, **현재는 안 넣되 follow-up 때 재평가**할 약한 후보. `B-4`(~라고 알려진) `C-7`(먼저·반면·결국) `C-8`(A인가 B인가) `F-1`(정도부사) `F-2`(동의어 이중수식) `F-3`(기능+역할 복합구) `H-2`(하지만/그러나 혼용) `H-4`(즉 남발) `I-2`(점/바/수/데) `I-4`(권고형 결말) `I-5`(~이 필요하다) `I-6`(~능력 연쇄). 대부분 번역에서는 원문을 따라가거나 빈도가 낮아 우선순위에서 밀린다.

> **분류 완전성**: 4.1~4.5의 ID 합집합 = upstream taxonomy 전체 ID 집합(A·B·C·D·E·F·G·H·I·J + PE15). resync 스크립트가 "어디에도 분류 안 된 ID = 신규"로 판정할 수 있도록 빠짐없이 분류한다.

## 5. 아키텍처

### 5.1 신규 — `translate-doc-assets/translationese-patterns.md`

system_prompt.md·glossary.json과 동형의 외부 asset. Step 5 본문 비대화를 막고 follow-up diff를 깔끔히 한다.

**헤더 (기계 판독 가능한 분류 대장)** — resync 스크립트가 파싱:

```yaml
---
source: epoko77-ai/im-not-ai
source_path: .claude/skills/humanize-korean/references/ai-tell-taxonomy.md
pinned_commit: "807172694d75"
pinned_date: "2026-05-07"
pinned_version: "v2.0"
# resync 스크립트가 upstream 신규 ID 판별에 사용하는 분류 대장
# (네 목록의 합집합 = upstream taxonomy 전체 ID. 여집합 = 신규 후보)
absorbed: [C-11, A-7, A-15, A-18, A-16, A-19, E-2, F-4, G-1, G-2, H-3, A-3, A-4, A-5, A-6, A-11, A-13, "PE15"]
already_covered: [A-1, A-2, A-8, A-9, A-10, A-12, A-14, B-1, B-2, B-3, E-1, E-4, F-5, H-1, I-1, I-3, J-3]
excluded: [C-1, C-2, C-3, C-4, C-5, C-6, C-9, C-10, C-12, D-1, D-2, D-3, D-4, D-5, D-6, D-7, E-3, E-5, E-6, E-7, A-17, G-3, J-1, J-2, J-4]
deferred: [B-4, C-7, C-8, F-1, F-2, F-3, H-2, H-4, I-2, I-4, I-5, I-6]
---
```

**본문**: 4.1·4.2 표를 패턴별 규칙으로 확장 — 각 ID마다 (정의 1줄, 처방 1~2줄, scholarship verbatim 예시, BAD→GOOD 1쌍). Step 4용/Step 5용 구분 명시.

### 5.2 수정 — `commands/translate-doc.md`

- **Step 1 (Load assets)**: `translationese-patterns.md`를 추가 로드 대상에 명시.
- **Step 4 (Translate)**: 문장 단위 패턴(C-11, A-7, A-15, A-18, E-2, F-4, PE15, A-3~A-6·A-11·A-13)을 번역 중 적용하도록 한 단락 추가. **흡수 규칙은 전부 `translationese-patterns.md` 한 파일에 두고 system_prompt.md는 수정하지 않는다** — ledger(분류 대장)와 규칙 텍스트를 같은 파일에 유지해 resync 정합성을 지킨다 (§9 Open Q#2 결정).
- **Step 5 (Self-review)**: density 패턴(A-16, A-19, G-1/G-2, H-3 — `3회 이상` 임계)을 **전체 번역본 재독** 체크리스트 항목으로 추가. 청킹 시 chunk별로는 빈도를 셀 수 없으므로 whole-doc re-read가 유일한 올바른 자리.
- **의역 강도(보수/균형/과감)와의 precedence** ⚠️ — 흡수 패턴을 두 등급으로 나눠 Step 4 의역 강도 선택과의 충돌을 막는다:
  - *표면 교정형* — **모든 의역 강도에서 적용.** 번역투 **오류 수정**이지 문체적 자유가 아니므로 보수에서도 고친다: `C-11` `A-7` `E-2` `F-4` `A-19` `PE15` `G-1/G-2` `H-3` `A-3~A-6·A-11·A-13`.
  - *구조 재구성형* — **의역 강도에 비례.** 문장 구조를 실제로 바꾸므로 보수에서는 명백한 경우만(3중 이상 중첩 관형구, 단락 3회+ 대명사) 최소 적용, 균형/과감에서 적극: `A-15` `A-16` `A-18`.
  - 이 등급 구분으로 "보수를 고른 사용자에게 문장 전면 재구성을 강요"하는 모순을 방지한다.
- **Hard rules**: source-blind 후처리를 하지 않는다(원문 대조 유지)는 원칙 1줄 추가.

### 5.3 신규 — `translate-doc-assets/resync_translationese.py`

수동 follow-up용 경량 스크립트. 동작:

1. upstream raw taxonomy를 fetch (`raw.githubusercontent.com/.../ai-tell-taxonomy.md`, main HEAD).
2. `gh api repos/epoko77-ai/im-not-ai/commits/main`으로 현재 HEAD SHA·날짜 조회.
3. `translationese-patterns.md` 헤더에서 `pinned_commit` + 분류 대장 4목록(absorbed/already_covered/excluded/deferred) 로드.
4. upstream taxonomy에서 패턴 ID + 심각도 추출 (정규식: `^### (?P<id>[A-J]-\d+)\..*\[(?P<sev>S\d)\]`).
5. **리포트**:
   - upstream에는 있으나 4목록 합집합 어디에도 없는 **신규 ID** → "검토 필요" 후보 (ID·심각도·정의 첫 줄).
   - 분류 대장에 있으나 심각도가 바뀐 ID → "재평가" 후보.
   - `deferred` ID 중 심각도가 올라간 것 → "보류 해제 검토" 후보.
   - `pinned_commit != upstream HEAD`면 "버전 관리 섹션 변경 있음" 알림 + diff 힌트.
6. 출력은 사람이 읽는 텍스트 리포트만. **자동 흡수·자동 파일 수정 없음** — 사용자가 검토 후 수동 반영.

언어/스타일: Python 3.10+, `python-coding-style` 준수(line 80, double quotes, 타입 힌트). 외부 의존 없이 표준 라이브러리(`urllib`/`subprocess`/`re`)만, 또는 환경에 있는 `gh`·`curl` 호출. 단일 파일 ≤ 150줄 목표.

## 6. 데이터 흐름

```
[번역 시]
  입력 .md
    ↓ Step 1: system_prompt + glossary + translationese-patterns 로드
    ↓ Step 4: 영어 원문 대조하며 번역 + 문장단위 번역투 패턴(C-11,A-7,A-15,A-18,E-2,F-4,PE15) 적용
    ↓ Step 5: 전체 재독 — 기존 14항 + density 패턴(A-16,A-19,G-1/2,H-3) 추가 점검
    ↓ Step 6: Write
  출력 .md

[follow-up 시 (수동, 비정기)]
  resync_translationese.py
    ↓ upstream taxonomy fetch + pinned_commit 비교
    ↓ 분류 대장 대조
    → 신규/심각도변경 패턴 리포트 → 사용자 검토 → 수동 흡수
```

## 7. 검증 방법

**1차 (필수) — 실제 문서 before/after 회귀 검증.** 패턴별 단위 예문 통과는 "규칙이 작동한다"만 보일 뿐, **목표(사용자의 실제 출력을 regression 없이 개선)**를 검증하지 못한다. 사용자는 이미 현재 결과에 만족하므로 최대 위험은 출력 악화다. 사용자가 이미 번역해 만족한 문서 1~2개를 패턴 ON으로 재번역해 diff를 확인:

- (a) **fidelity 불변** — 영어 원문 대비 의미가 변하지 않았는가. 특히 `A-16` 대명사 생략이 '누가 무엇을 했는지' 모호성을 만들지 않는지 집중 점검.
- (b) **구조 불변** — frontmatter byte-identical, 마크다운 구조·코드블록·inline code·URL·글로서리 적용이 모두 그대로인가.
- (c) **개선 방향** — diff가 단순 '변화'가 아니라 번역투가 줄어든 '개선'인가. 변화량이 사용자가 고른 의역 강도 등급(§5.2 precedence)을 넘지 않는가.

**2차 — 흡수 정확성.** 각 흡수 패턴마다 reference 파일의 BAD→GOOD 예문 1쌍이 있고, 샘플에서 해당 패턴이 GOOD 방향으로 교정되는지 확인.

**3차 — 스크립트.** absorbed에서 한 ID를 임시로 빼거나 pinned_commit을 과거 SHA로 두고 실행 → 해당 ID가 '신규/검토 필요'로 리포트되는지 확인. `gh`/`curl` 부재 시 명확한 에러 메시지.

## 8. 비목표 (YAGNI)

- 후처리 파이프라인 연결 (§2에서 기각).
- im-not-ai의 정량 metric(`metrics_v2.py`)·5인 에이전트·monolith 도입.
- 구조 변경 처방(헤딩/불릿/이모지) 흡수.
- 자동 watch/cron 동기화 (markdown changelog 상대로 과함).
- D 카테고리(AI 상투구) 흡수 — 번역은 원문 충실성이 우선.

## 9. Open Questions

- reference 파일 본문에서 패턴별 BAD→GOOD 예문을 scholarship verbatim 그대로 쓸지, translate-doc 실제 번역 맥락(에세이/기술문서)에 맞춰 새로 만들지 — 후자가 사용자 워크플로우에 더 적합할 수 있음. (구현 plan에서 결정)

> **해결됨**: ~~`A-3~A-6·A-11·A-13`을 system_prompt 표 보강 vs translationese-patterns.md~~ → translationese-patterns.md 한 파일에 ledger와 규칙을 함께 둔다(§5.2). system_prompt.md는 건드리지 않는다.
