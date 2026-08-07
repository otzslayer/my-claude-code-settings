---
title: Build-stage complexity scoring double-counted planning-time scope signals
date: 2026-07-04
category: workflow-issues
module: rules/hybrid-workflow.md
problem_type: workflow_issue
applies_when:
  - "scoring model/effort for the build (ce-work) stage of the hybrid pipeline"
  - "the full pipeline was triggered by file-count, new-module/pattern, or API/schema-change signals at planning time"
  - "deciding whether to escalate an execution-stage subagent from Sonnet to Opus"
tags:
  - "model-routing"
  - "cost-calibration"
  - "complexity-scoring"
  - "build-stage"
  - "escalation-policy"
  - "sonnet-opus"
  - "double-counting"
---

# Build-stage complexity scoring double-counted planning-time scope signals

## 배경 (Context)

`~/.claude` 저장소는 CLAUDE.md가 AI 모델·effort 라우팅 결정을 전적으로 위임하는 `rules/hybrid-workflow.md`를 "Compound + Superpowers Hybrid Workflow" 파이프라인의 단일 진실 공급원(single source of truth)으로 삼고 있다. `docs/dynamic-model-selection` 브랜치(커밋 `22f564a`)는 이 파일의 모델 라우팅 방식을 갈아엎었다.

기존 방식은 단순한 2단계 구조였다: 설계·계획·디버깅(진짜로 열린 결말의 추론이 필요한 단계)만 Opus·xhigh로 올리고, 빌드를 포함한 모든 실행 단계(TDD, ce-work, 검증, 커밋)는 Sonnet·medium에 고정했다.

새 브랜치는 이를 0~10점 복잡도 스코어링 시스템으로 대체했다. 각 작업을 "기저 점수(base score, 작업의 인지적 성격)"와 "가산 신호(additive signals, 작업 범위 — 파일 수, 신규 모듈/패턴, API·스키마 변경 등)"의 합으로 채점하고, 그 총점을 0-2(Sonnet·low) / 3-5(Sonnet·medium) / 6-7(Opus·high) / 8-10(Opus·xhigh) 밴드에 매핑한다.

이 새 스코어링 체계를 도입한 뒤, 비용 분석 관점의 질문 하나가 이 설계에 숨어 있던 오정렬(miscalibration)을 드러냈다. 이 문서는 그 오정렬의 정체와 그것을 바로잡기 위해 채택한 지침을 기록한다.

## 지침 (Guidance)

**빌드·실행 단계는 범위(scope) 신호와 무관하게 기본적으로 Sonnet·medium을 사용한다.** 스코어링 표에서 빌드/실행은 "기계적 실행(base 1)"에 해당하는 작업 성격이며, 이 기저 점수는 계획 단계에만 유효한 범위-가산 신호(파일 수, 신규 모듈/패턴, 공개 API·스키마 변경 등)에 의해 밀어 올려져서는 안 된다.

Opus로의 에스컬레이션은 오직 **사후적(reactive)**으로만 일어나야 한다 — 문서(§4 Escalation policy)에 이미 정의된 재실행 게이트(re-run gate)를 통해서만, 즉 실행이 계획이 전혀 예견하지 못한 무언가를 드러낼 때만 발동한다. 예를 들면:

- TDD의 RED→GREEN 사이클이 막혀서 열린 결말의 근본 원인 디버깅으로 전환되는 경우 (이는 완전히 다른 작업 범주 — base 5 디버깅 — 로 재채점된다)
- 되돌리기 어려운 변경에서 테스트·타입체크가 실패하는 경우

계획 단계의 범위 신호(파일 수, 신규 모듈, API/스키마 변경)만으로 사전에(pre-emptively) 에스컬레이션하는 것은 규칙 위반이다.

다만 사후 에스컬레이션 경로 자체를 완전히 없애서는 안 된다. 다음과 같은 잔여 실패 유형이 여전히 온디맨드 에스컬레이션을 정당화한다:

- 빌드 세션 내부에 파묻힌 디버깅
- 계획과 실제 구현 사이의 큰 괴리가 실행 중간에 발견되는 경우
- 동시성·보안·마이그레이션처럼 계획이 의도는 명시할 수 있어도 구현의 미묘한 함정을 전부 예견할 수 없는, 진짜로 새로운 크로스커팅(cross-cutting) 작업 단위

## 이것이 중요한 이유 (Why This Matters)

**이중 계산(double-counting) 오류.** 파일 수, 신규 모듈/패턴, 공개 API·스키마 변경 같은 가산 신호들은 "계획(planning) 시점" 복잡도의 정당한 척도다 — 해법을 어떻게 **설계**할지 결정할 때 의미가 있다. 그런데 새 스코어링 체계는 이 동일한 신호들을 빌드/실행 단계(ce-work)에도 **재적용**하고 있었다. 그 결과 "이 작업은 5개 파일을 건드린다"거나 "공개 API를 변경한다"는 이유만으로, 이미 상세하게 확정된 계획을 그대로 실행할 뿐인 단계가 범위만으로 Opus·high로 밀려 올라갔다. 계획이 이미 모든 설계적 판단을 흡수한 뒤이므로, 실행이 시작되는 시점에는 파일 수나 API 변경 여부가 더 이상 "결정 하나하나의 난이도"를 나타내지 않는다 — 그것은 오히려 "기계적 작업의 물량"을 나타낼 뿐이며, 이는 모델 등급을 올리는 것이 아니라 단위 세분화(unit granularity, 실행 단위를 더 적은 수의 더 큰 덩어리로 묶는 것)로 다뤄야 할 문제다.

**아이러니한 피드백 루프.** 더 나쁜 것은, "풀 파이프라인 활성화"를 트리거하는 신호(3개 이상 파일, 신규 모듈, API/스키마 변경)가 복잡도 점수를 부풀리는 신호와 정확히 동일하다는 점이다. 즉 범위가 있는 작업에 대해 풀 파이프라인을 돌리면, 모든 단계 중 보통 가장 많은 토큰을 소모하는 단계(빌드)가 저렴한 Sonnet에서 대략 5배 더 비싼 모델로 체계적으로 에스컬레이션되어, 품질상의 상응하는 이득 없이 총비용만 끌어올리게 된다.

**토큰 수와 비용의 괴리.** 두 스킴 사이에서 원시 토큰 **수**(count)는 대체로 평평하게 유지된다(effort 레벨 변화가 부분적으로 서로 상쇄하기 때문). 그러나 **비용**은 특정하게 상승하는데, 이는 가장 토큰을 많이 쓰는 단계(빌드)에서 모델 **믹스**가 Opus 쪽으로 쏠리기 때문이다. 토큰 수와 비용은 같은 축이 아니며 서로 어긋날 수 있다 — 토큰 중립적으로 보이는 설계가 실제로는 훨씬 더 비쌀 수 있다는 뜻이다.

## 적용 시점 (When to Apply)

- 이 저장소의 하이브리드 파이프라인에서 빌드/실행 단계(ce-work)의 모델·effort를 스코어링할 때.
- 더 일반적으로는, 동일한 작업 단위의 계획 단계와 실행 단계를 **모두** 채점하는 어떤 복잡도 스코어링 체계에도 적용된다 — 계획 시점 범위 신호를 실행 단계에 재사용하려는 유혹이 있을 때마다 이 원칙을 점검해야 한다.

## 예시 (Examples)

**Before(오정렬된 동작)**: 6개 파일을 건드리고, 신규 모듈을 추가하며, 공개 API를 변경하는 계획이 있다고 하자. 기존(오정렬된) 스코어링 체계에서는 이 범위 신호들이 그대로 상속되어 빌드 단계가 Opus·high로 에스컬레이션된다 — 실행이 아직 아무 문제도 겪지 않았는데도.

**After(수정된 동작)**: 동일한 계획이라도 빌드는 기본적으로 Sonnet·medium에 머문다. 실행 도중 재실행 게이트(re-run gate)의 트리거 — 예컨대 테스트 실패나 디버깅 교착 — 를 실제로 만나기 전까지는 에스컬레이션하지 않는다.

**정당한 사후 에스컬레이션의 예**: 빌드 세션 중 TDD의 RED→GREEN 전환이 매끄럽게 되지 않고, 원인을 알 수 없는 실패가 반복되어 열린 결말의 근본 원인 디버깅으로 바뀐다. 이 시점에 작업은 base-5 디버깅으로 재채점되고, 그제서야 — 사전이 아니라 사후에 — Opus로 에스컬레이션한다.

## 맺음말: CLAUDE.md를 수정하지 않은 이유

CLAUDE.md는 이 스코어링·에스컬레이션 세부 사항 전체를 `rules/hybrid-workflow.md` §3(복잡도 스코어링)·§4(에스컬레이션 정책)에 참조로 위임하며, 해당 파일을 파이프라인의 단일 진실 공급원으로 명시적으로 선언하고 있다. 이 규칙을 CLAUDE.md에도 중복 기술하면 시간이 지나며 `hybrid-workflow.md`와 어긋날 수 있는 두 번째 사본이 생기게 된다. 그래서 `hybrid-workflow.md`만 수정했다.

**핵심 원칙 요약**: "계획의 범위를 근거로 미리 Opus 비용을 지불하지 말고, 실행이 실제로 필요성을 증명했을 때 온디맨드로 지불하라." 계획 시점 복잡도 신호(파일 수, 신규 모듈, API/스키마 변경)는 계획을 어떻게 설계하고 얼마나 철저히 리뷰할지에 반영되어야 하며, 실행이 시작된 뒤 두 번째 복잡도 승수로 재적용되어서는 안 된다 — 계획이 이미 그 복잡도를 구체적인 단계들에 흡수해 놓았기 때문이다.

## Related

- 이 학습과 겹치는 기존 solutions 문서는 없다 (docs/solutions/ 내 유일한 기존 문서인 `runtime-errors/hook-skill-extraction-non-interactive-shell-env-mismatch.md`는 훅 스크립트의 셸 환경 버그로, 주제가 무관함). 모델 라우팅·복잡도 스코어링에 관한 첫 학습이다.
