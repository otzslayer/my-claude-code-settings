# 리뷰어 분기 (§5)

리뷰어를 dispatch할 때만 필요하다. 과업 채점·에스컬레이션 근거는 `scoring.md`(§3·§4)에 있다.

quick card가 이미 담고 있는 것: **전 리뷰어 `model=opus` 고정, 세션 모델은 전환 금지.**
이 파일은 그 이유를 담는다.

- 리뷰는 본질적으로 개방형 적대적 추론(base 5)이라 리뷰어는 전원 `model=opus`로 dispatch한다. 분기는 없다.
- **플러그인 스킬을 고쳐서 이걸 달성하지 말 것** — `~/.claude/plugins/...`는 머신 상태라 플러그인 업데이트 때 덮어써진다. 강제 지점은 상주 규칙 파일이고, 그 파일이 스킬의 내장 모델 티어링보다 우선한다.
- `effort`는 dispatch로 지정할 수 없다(`Agent` 툴에 파라미터가 없어 디스패치 세션에서 상속된다). 그래서 pin하는 건 `model`뿐이고, "opus·high 리뷰어"라는 표기는 effort 고정이 아니라 상속의 결과다 — resting `effortLevel: high`면 리뷰어도 high로 착지하고, 부모가 `xhigh`면 리뷰어도 `xhigh`가 된다.
- `ce-doc-review`는 ce-plan의 필수 Phase 5.3.8로 모든 `OUTPUT_FORMAT=md` 계획에 대해 headless 자동 실행된다(`OUTPUT_FORMAT=html`일 때만 건너뜀). **`/ce-plan`과 같은 세션 안**이라 모델을 바꿀 `/clear` 경계 자체가 없다. `ce-code-review`는 Phase 2'에서 돈다.
- 리뷰 dispatch를 위해 세션 모델을 전환하지 않는다 — 캐시 재로딩 비용이 크다.
