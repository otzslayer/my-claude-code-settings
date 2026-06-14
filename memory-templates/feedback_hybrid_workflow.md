---
name: feedback-hybrid-workflow
description: Compound + Superpowers 하이브리드 워크플로우 spec 채택. ce-compound 산출물은 docs/solutions/만, Tier 0/1(CLAUDE.md, auto memory) 자동 변경 금지
metadata:
  type: feedback
---

2026-05-19 spec(`~/my-claude-code-settings/docs/superpowers/specs/2026-05-19-compound-superpowers-hybrid-workflow.md`) 채택. 7단계 파이프라인(Phase 1 superpowers:brainstorming → Phase 2 ce-plan + plannotator → Phase 2' TDD + ce-work + ce-code-review → Phase 3 verification + ce-compound headless + finishing-a-development-branch)이 글로벌 하네스에 적용됨.

**규칙**:
- `/ce-compound` 산출물은 프로젝트 로컬 `docs/solutions/`에만 둔다.
- Tier 0 (`~/.claude/CLAUDE.md`, `~/.claude/rules/`)과 Tier 1 (`~/.claude/projects/.../memory/`, `~/.claude/.remember/`)은 ce-compound·자동 워크플로우가 절대 자동 변경하지 않는다. 사용자 수동 변경만 허용.
- `superpowers:writing-plans`는 더 이상 풀 파이프라인의 plan 단계가 아니다. Plan Mode 안에서는 `/ce-plan`이 메인.
- 95% confidence opener는 brainstorming의 첫 turn에 자연스럽게 녹인다 (별도 표 행 아님).
- TDD는 트리비얼 작업(타입/린터 픽스, 단일 파일 리네임, docstring 정리, 의존성 버전만 등)에서 면제 가능. 면제 판단 애매하면 `AskUserQuestion`.

**Why**: 사용자가 Tier 0/1 자동 변경으로 인한 메모리 시스템 오염을 명시적으로 차단했다 (spec §1 핵심 원칙, §4 정책). plannotator 자동 게이트와 ce-* 도구의 워크플로우 가치를 보존하면서, 글로벌 행동 규칙·메타 메모리는 사용자 통제 하에 유지한다.

**How to apply**:
- 새 세션에서 ce-compound·자동 워크플로우가 `~/.claude/CLAUDE.md`, `~/.claude/rules/*`, `~/.claude/projects/.../memory/*`을 자동 수정하려 하면 차단하고 사용자에게 확인.
- "writing-plans 써서 plan 짜줘" 요청이 와도 Plan Mode 안이면 `/ce-plan`을 안내.
- Phase별 라우팅은 [[feedback-search-tools]], [[feedback-global-vs-project-scope]]의 도구·범위 규칙과 함께 적용.
