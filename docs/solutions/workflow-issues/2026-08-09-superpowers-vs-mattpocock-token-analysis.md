# superpowers 대 mattpocock-skills 토큰 사용량 분석

작성일: 2026-08-09
대상 버전: superpowers 6.2.0, mattpocock-skills 1.2.3

## 요약

두 프레임워크를 비교한 글은 여럿 있다. 그러나 **같은 과제를 두 프레임워크로 각각 돌려 토큰을 잰 head-to-head 벤치마크는 없다.** 존재하는 비교는 철학·용도 대조이고, 유일한 통제 실험은 superpowers와 제3의 프레임워크(agent-skills)를 붙인 단일 과제 실험이다. 따라서 이 문서의 비교 수치는 로컬 파일 측정과 구조 분석에서 도출한 추정이며, 웹 자료는 기준선 측정과 구조 주장을 교차 검증하는 용도로 썼다.

결론은 한쪽의 일방적 우세가 아니다.

- **새 기능 개발**: mattpocock이 15~20% 유리. 차이의 출처는 태스크 루프가 아니라 앞단 사고 단계와 superpowers가 강제하는 최종 전 브랜치 리뷰다.
- **버그 수정**: superpowers가 약 20% 유리. 단 사용자 CLAUDE.md의 Planning Trigger가 발동하면 3배 이상으로 역전된다.

## 근거 등급

| 등급 | 내용 | 신뢰도 |
|---|---|---|
| A. 직접 측정 | 로컬 플러그인 파일 크기, 스킬 본문에 명시된 디스패치 구조, 이 세션의 시스템 프롬프트 관측 | 높음 |
| B. 외부 측정 | obra/superpowers 이슈 #190의 `/context` 기반 측정, zenn의 오버헤드 측정, addyosmani의 단일 과제 통제 실험 | 중간, 재현·표본 한계 |
| C. 외부 주장 | 블로그·리뷰의 절감률 수치 | 낮음, 방법론 미공개 |
| D. 추정 | 에이전트 실행당 토큰 단가 | 가정, 감도 분석으로 보완 |

## A. 로컬 측정

### 지시문 크기

`SKILL.md` 전체 합계.

| 플러그인 | 합계 bytes | 스킬 수 |
|---|---|---|
| superpowers 6.2.0 | 127,957 | 14 |
| mattpocock-skills 1.2.3 | 116,851 | 25 |

총량은 비슷하다. 그런데 **세션 시작 시 실제로 주입되는 양**이 다르다.

superpowers는 SessionStart 훅으로 `using-superpowers/SKILL.md`(3,063 bytes, 약 800 토큰)를 매 세션 주입한다. 이 문서를 작성한 세션의 시스템 프롬프트에서 직접 확인했다. mattpocock은 주입하는 훅이 없고, 스킬 목록의 한 줄 설명만 실린다.

즉 고정 오버헤드 차이는 세션당 약 800 토큰이다. 실무적으로 무시할 수준이다. 다만 이 숫자는 본문 주입분만 센 것이고, 스킬 목록에 실리는 설명 줄은 양쪽 모두 별도로 든다. mattpocock이 25개, superpowers가 14개라 설명 줄까지 세면 격차는 더 좁아지거나 뒤집힌다. 어느 쪽이든 무시할 규모다.

### 파이프라인별 지시문

eval 픽스처(`test-pressure-1/2/3.md`·`test-academic.md`·`CREATION-LOG.md`)는 런타임에 안 실리므로 제외했다.

| superpowers | bytes | mattpocock | bytes |
|---|---|---|---|
| brainstorming/SKILL | 10,047 | grilling + domain-modeling | 10,364 |
| writing-plans/SKILL | 6,907 | to-spec + to-tickets | 8,742 |
| subagent-driven-development/SKILL | 28,077 | implement/SKILL | 433 |
| test-driven-development/SKILL | 9,015 | tdd/SKILL | 3,584 |
| requesting-code-review 일체 | 8,169 | code-review/SKILL | 6,634 |
| systematic-debugging/SKILL | 9,465 | diagnosing-bugs/SKILL | 8,969 |

`implement` 433 bytes 대 SDD 28,077 bytes는 65배 차이지만 **총 비용의 결정 요인이 아니다.** 100만 토큰 규모 작업에서 7천 토큰 한 번의 차이는 반올림 오차다. 이 숫자를 헤드라인으로 쓰면 객관적으로 보이면서 실제로는 틀린 글이 된다.

### 디스패치 구조

실제 비용을 가르는 변수다. 스킬 본문에서 확인했다.

| 작업 단위당 | implementer급 컨텍스트 | reviewer급 컨텍스트 |
|---|---|---|
| superpowers SDD | 1 (implementer 서브에이전트) | 1~2 (task-reviewer + 조건부 re-review, 최대 5라운드) |
| mattpocock | 1 (`/clear` 후 메인 윈도) | 2 (Standards·Spec 병렬 팬아웃) |

근거 위치.

- `subagent-driven-development/SKILL.md:8` 태스크마다 새 implementer, 이후 태스크 리뷰, 마지막에 전 브랜치 리뷰
- `subagent-driven-development/SKILL.md:103-105` 최종 리뷰 후 수정 디스패치와 범위 재리뷰
- `code-review/SKILL.md:58,72` 서브에이전트는 정확히 2개, 스펙이 없으면 Spec 축 스킵
- `ask-matt/SKILL.md:23` mattpocock도 티켓마다 `/clear`

마지막 항목이 중요하다. mattpocock이 재오리엔테이션 비용을 피하는 게 아니다. 상주 코디네이터 없이 한 번만 낼 뿐이다. 태스크 루프 자체는 사실상 동률이고, 오히려 리뷰 팬아웃이 2개라 mattpocock이 조금 더 쓴다.

## B·C. 웹 자료

### 검색으로 확인된 것

**obra/superpowers 이슈 #190** (등급 B). 플러그인이 시작 시 전체 스킬 정의를 미리 실어 약 22,000 토큰, 200k 컨텍스트의 11%를 잡아먹는다는 보고다. `/context` 출력과 파일 바이트 수를 대조해 측정했고 이슈는 열린 상태다. 문서화된 progressive disclosure를 지키면 기준선이 약 1,400 토큰으로 내려간다고 주장한다.

**현재 환경에서는 재현되지 않는다.** 이 세션에서 실제로 주입된 건 `using-superpowers` 본문 하나(약 800 토큰)뿐이고, 나머지 13개 스킬은 한 줄 설명으로만 등장한다. 전체 `SKILL.md` 합계가 127,957 bytes, 약 32k 토큰이므로 전부 실렸다면 22k보다 더 컸을 것이다. 왜 다른지는 확인하지 않았다. 이슈 날짜를 못 봤으므로 버전 차이라고 단정하지 않는다.

zenn의 비교 글(등급 C, 그러나 자체 측정)이 이를 뒷받침한다. superpowers 5.1.0에서 `using-superpowers` 본문 기준 오버헤드를 약 1,350 토큰으로 쟀다. 6.2.0에서 낸 800 토큰과 같은 자릿수고, #190의 22k와는 한 자릿수 이상 벌어진다. 같은 글은 mattpocock에 SessionStart 훅이 없어 호출할 때만 실린다고 정리한다.

**9% 비용 절감·14% 토큰 절감** (등급 C). geeky-gadgets 기사의 수치다. 원문은 "12회 테스트 실행, 플러그인 있음 6회와 없음 6회"라고만 밝힌다. 테스트 대상 프로젝트·조건·수행 주체·원자료 링크가 전부 없다. 그리고 결정적으로 이건 **superpowers 대 플러그인 없음**의 비교라 지금 질문에 답하지 않는다.

**63% 토큰 비용 절감** (등급 C). mattpocock 측 progressive disclosure 주장이다. andrew.ooo 리뷰는 이를 저자가 검증 없이 옮긴 마케팅 문구로 평가하고, skillselion 정리본은 그 최적화의 실제 동인이 측정이 아니라 스킬 이름을 산출물에 맞춰 바꾼 것이었다고 적는다. 근거로 쓸 수 없다.

**62% 출력 토큰 감소** (등급 C, 그러나 실측). andrew.ooo가 30턴 디버깅 세션에서 직접 측정한 유일한 숫자다. 다만 대상이 `/caveman` 스킬이라 여기서 다루는 engineering 세트와 무관하다.

**mcp.directory 리뷰**. 벤치마크 수치는 하나도 없다. 다만 구조 주장 하나가 로컬 측정과 일치한다. 태스크마다 implementer 하나와 리뷰어 둘을 띄우므로 10개 태스크 계획이면 30회 이상의 디스패치가 된다는 서술이다. 위 디스패치 표와 같은 그림이다.

**addyosmani/agent-skills의 `docs/comparison.md`** (등급 C, 통제 실험). 유일하게 발견된 head-to-head 실험이다. 같은 모델·저장소·프롬프트로 superpowers와 agent-skills를 붙였다.

| 지표 | agent-skills | superpowers |
|---|---|---|
| 코드 착수까지 | 약 8분 | 약 12분 |
| 검증 패스 횟수 | 7 | 5 |
| 토큰 효율 | 사실상 동일 | 사실상 동일 |
| 재계획 | 1회 | 1회 |

문서 스스로 "개발자 한 명의 단일 과제 실험이지 벤치마크가 아니다"라고 못박는다. 비교 대상도 mattpocock이 아닌 제3의 프레임워크다.

그럼에도 눈여겨볼 지점이 있다. **토큰 효율이 사실상 동일하게 나왔다는 결과**다. superpowers가 앞단 사고에 더 쓰고 상대는 검증에 더 쓰는 식으로 상쇄됐다. 아래 추정에서 낸 17% 격차보다 작은 차이다. 표본이 1이라 뒤집을 근거는 아니지만, 격차를 낙관적으로 잡지 말라는 신호로는 읽어야 한다.

**zenn의 비교 글**은 선택 기준을 이렇게 정리한다. GitHub Issues 기반 개발·karpathy-guidelines 정렬·surgical changes 지향이면 mattpocock, 병렬 서브에이전트 대규모 실행 관리나 에이전트의 자체 판단을 구조적으로 막아야 하면 superpowers다. 공존은 기능 중복이 아니라 철학 충돌 때문에 어렵다고 본다. superpowers의 "1% 가능성이라도 있으면 반드시 스킬을 호출하라"가 오탐을 만든다는 지적이다.

### 정리

웹에서 얻은 실질 소득은 넷이다.

- 두 프레임워크의 head-to-head 토큰 벤치마크는 없다는 확인
- superpowers 기준선 오버헤드에 대한 독립 측정(1,350 토큰)이 로컬 측정(800 토큰)과 일치하고 #190의 22k를 반박한다는 점
- superpowers의 태스크당 3회 디스패치 구조에 대한 교차 검증
- 제3자 통제 실험에서 프레임워크 간 토큰 효율이 사실상 동일하게 나왔다는 반대 방향 신호

절감률로 홍보되는 수치들(9%·14%·63%)은 방법론이 없거나 질문과 다른 것을 비교한다.

## D. 시나리오별 추정

### 가정 단가

| 구분 | 범위 | 중앙값 |
|---|---|---|
| implementer급 실행 1회 | 80k~150k | 110k |
| reviewer급 실행 1회 | 25k~50k | 35k |
| 대화형 인터뷰 단계 | 30k~60k | 45k |

### 시나리오 1. 새 기능, 티켓 5개

| 단계 | superpowers | mattpocock |
|---|---|---|
| 앞단 사고 | brainstorming 70k + writing-plans 60k + SDD 코디네이터 70k = 200k | grill-with-docs 50k + to-spec·to-tickets 45k = 95k |
| 태스크 루프 ×5 | (110 + 35 + 17) × 5 = 810k | (110 + 35×2) × 5 = 900k |
| 최종 전 브랜치 리뷰 | 45k + 110k + 35k = 190k | 없음 |
| 합계 | **약 1.20M** | **약 1.00M** |

차이 약 205k, 17%다.

차이의 출처를 분해하면 이렇다. 태스크 루프에서는 mattpocock이 90k 더 쓴다. 리뷰를 2개로 팬아웃하기 때문이다. 그럼에도 이기는 이유는 앞단이 105k 가볍고, superpowers가 태스크별 리뷰 위에 최종 브랜치 리뷰를 한 번 더 강제하기 때문이다.

그 190k는 낭비가 아니라 커버리지 대가다. mattpocock은 티켓 단위로만 보므로 티켓 경계를 가로지르는 결함을 구조적으로 놓친다.

감도 분석. implementer급을 150k로 올리면 1.44M 대 1.20M(17%), reviewer급을 50k로 올리면 1.35M 대 1.15M(15%). 결론이 유지된다. 유일하게 크게 벌어지는 경우는 스펙이 없어 Spec 축이 스킵될 때(32%)인데, `/to-tickets`가 스펙을 만들므로 이 경로에서는 일어나지 않는다.

반대 방향 근거도 적어둔다. addyosmani 문서의 통제 실험은 프레임워크 간 토큰 효율을 사실상 동일하게 측정했다. 비교 대상이 다르고 표본이 1이라 이 추정을 뒤집지는 못하지만, 15~20%를 상한으로 보는 편이 안전하다.

### 시나리오 2. 기존 버그 수정

지시문 무게는 사실상 동률이다. 9,465 대 8,969.

| 단계 | superpowers | mattpocock |
|---|---|---|
| 진단 루프 | systematic-debugging 메인 95k | diagnosing-bugs 메인 95k |
| 리그레션 테스트 | TDD 인라인 (포함) | `/tdd` 인라인 (포함) |
| 리뷰 | 리뷰어 1개 35k | 리뷰어 2개 70k |
| 합계 | **약 130k** | **약 165k** |

superpowers가 약 20% 유리하다. 리뷰어를 하나만 띄우기 때문이다.

다만 superpowers 쪽 비용은 이봉분포다. 수정이 사용자 CLAUDE.md의 Planning Trigger(3개 이상 파일·아키텍처 결정·새 의존성·공개 API나 스키마 변경)에 걸리는 순간 경로가 `brainstorming → writing-plans → subagent-driven-development`로 승격되어 400k 이상으로 뛴다. mattpocock의 `/diagnosing-bugs`에는 그런 승격 게이트가 없어 165k 근처에 머문다.

**비용을 결정하는 건 스킬 모음이 아니라 사용자의 CLAUDE.md다.**

## 캐싱

방향만 적는다. 수명이 짧은 신규 컨텍스트를 많이 띄우는 쪽이 초기 로드에서 캐시 미스를 더 자주 먹고, 오래 사는 윈도는 한 번 내고 이후 재전송에서 크게 할인받는다. 다만 두 흐름의 작업 단위당 디스패치 수가 3개 대 3개로 비슷해서 이 요인이 결론을 뒤집지 않는다. 배수는 붙이지 않는다. 근거가 없다.

## 한계

- 실행 단가는 추정이다. 실제 측정이 아니다.
- 두 프레임워크를 같은 과제에 돌린 A/B 데이터가 로컬에도 웹에도 없다. 가장 가까운 자료(addyosmani)는 비교 대상이 다르고 표본이 1이며, 그 결과는 토큰 효율 동률이었다.
- 태스크 5개·버그 1개라는 규모 가정에 결과가 의존한다. 태스크 수가 늘수록 최종 브랜치 리뷰의 고정비 비중이 줄어 superpowers가 상대적으로 유리해진다.
- 품질 차이를 비용에 환산하지 않았다. 최종 브랜치 리뷰의 가치는 계산에 안 들어가 있다.

## 권고

토큰만 보면 기능은 mattpocock, 버그는 superpowers가 맞다. 그런데 한 저장소에서 둘을 섞으면 계획의 진실 원천이 이슈 트래커와 `docs/plans/`로 갈라진다. 15~20%는 그 혼선을 감수할 만한 차이가 아니다.

기능 중심 저장소라면 mattpocock으로 통일하고 버그도 `/diagnosing-bugs`로 받는 편이 낫다. 버그에서 20% 손해를 보지만 Planning Trigger 승격 위험이 사라져 기대값은 오히려 유리하다.

토큰 밖의 근거도 같은 방향을 가리킨다. zenn의 선택 기준은 GitHub Issues 기반 개발·karpathy-guidelines 정렬·surgical changes 지향을 mattpocock 쪽으로 분류한다. 이 사용자의 `~/.claude/rules/`에는 `karpathy-principles.md`가 있고 `boundaries.md`에 Surgical Changes 절이 따로 있다. 세 조건 중 둘이 이미 성립한다.

반대로 superpowers를 유지할 이유는 병렬 서브에이전트 대규모 실행 관리와, 에이전트가 스스로 판단해 절차를 건너뛰는 것을 구조적으로 막는 강제력이다. 이 두 가지가 필요 없다면 토큰과 철학 양쪽에서 mattpocock이 앞선다.

## 출처

- [All Skills Preloaded at Startup Consuming 22k+ Tokens · Issue #190 · obra/superpowers](https://github.com/obra/superpowers/issues/190)
- [Reduce Claude Code Token Usage With the Superpowers Plugin (Geeky Gadgets)](https://www.geeky-gadgets.com/superpowers-plugin-claude-code/)
- [Superpowers for Claude Code: Still Worth It in 2026? (mcp.directory)](https://mcp.directory/blog/superpowers-skill-worth-it-2026)
- [Matt Pocock's Skills Review (andrew.ooo)](https://andrew.ooo/posts/matt-pocock-skills-claude-code-review/)
- [Matt Pocock's skills, mapped (Skillselion)](https://skillselion.com/guides/matt-pocock-skills-map)
- [Comparing superpowers vs. mattpocock/skills (zenn.dev/kanagen)](https://zenn.dev/kanagen/articles/claude-code-skills-superpowers-vs-mattpocock?locale=en)
- [addyosmani/agent-skills `docs/comparison.md`](https://github.com/addyosmani/agent-skills/blob/main/docs/comparison.md)
- [Superpowers vs Matt Pocock's skills (nocoders)](https://www.nocoders.com/blog/superpowers-vs-pocock-agent-skills/)
