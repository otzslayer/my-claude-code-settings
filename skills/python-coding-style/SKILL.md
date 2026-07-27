---
name: python-coding-style
description: "Python coding style: 프로젝트 ruff 설정 우선 규칙, 불변성, 에러 핸들링·입력 검증 형태, 크기·중첩 냄새 임계값, 새 프로젝트용 ruff 시작 설정. Use when: (1) writing or editing any Python (.py) file, (2) reviewing Python code style, (3) fixing Ruff/lint errors, (4) scaffolding ruff config for a new Python project. Apply BEFORE writing Python code, not after."
---

# Python Coding Style

## 우선순위 (먼저 읽을 것)

**프로젝트에 `pyproject.toml`의 `[tool.ruff]` 또는 `ruff.toml`이 있으면 그쪽이 절대 우선이다.** 줄 길이·따옴표·규칙 집합은 기계가 강제하는 프로젝트별 설정이며, 이 문서의 서술로 덮어쓰지 않는다. 프로젝트가 100자면 100자가 맞다.

설정이 이미 있는 프로젝트에서는 아래 "새 프로젝트 시작 설정"을 **건너뛰고** 산문 규칙(불변성 이하)만 적용한다.

```bash
uv run ruff check --fix . && uv run ruff format .
```

## 새 프로젝트 시작 설정 (설정 파일이 없을 때만)

```toml
[tool.ruff]
line-length = 80
target-version = "py311"

[tool.ruff.lint]
select = ["E", "W", "F", "I", "UP", "N", "S", "SIM", "ARG", "B", "C4"]
ignore = ["E501", "S603"]  # E501은 formatter가 처리, S603은 오탐 과다

[tool.ruff.lint.flake8-bugbear]
# FastAPI·Typer의 인자 기본값 호출은 의도된 패턴 (B008 예외)
extend-immutable-calls = [
    "fastapi.Depends", "fastapi.Query", "fastapi.Path",
    "fastapi.Body", "fastapi.Header",
    "typer.Argument", "typer.Option",
]

[tool.ruff.lint.per-file-ignores]
"__init__.py" = ["F401"]
"tests/**" = ["S101", "S106", "SIM117", "ARG001", "E741"]
```

포맷은 ruff 기본값을 그대로 쓴다 (4-space indent, double quotes).

타입 체크는 `uv run ty check`. `[tool.mypy]`를 새로 핀하지 말 것 — mypy는 기존 프로젝트가 이미 핀해둔 경우의 폴백이다.

---

아래는 **ruff가 검사하지 않는** 규칙이다. 위 설정이 통과해도 별도로 지켜야 한다.

## 불변성 (Critical)

새 객체를 만들고, 절대 제자리 변경하지 않는다:

```python
# CORRECT
return {**user, "name": name}
# Pydantic
return user.model_copy(update={"name": name})
```

## 에러 핸들링

로그에는 원인을, 호출자에게는 사용자용 메시지를:

```python
try:
    result = await operation()
except ValueError as e:
    logger.error(f"Failed: {e}")
    raise HTTPException(status_code=400, detail="User message")
```

`print()` 대신 `logging`을 쓴다.

## 입력 검증

원시 타입 대신 제약이 붙은 Pydantic 모델로 받는다:

```python
class UserInput(BaseModel):
    email: EmailStr
    age: int = Field(ge=0, le=150)
```

## 크기·구조 (게이트가 아니라 냄새 임계값)

아래 숫자는 ruff가 강제하지 않는다. **넘었다고 위반이 아니라, 넘었으면 쪼갤 근거를 한 번 대보라는 신호**다. 근거가 서면 그대로 둔다.

- **함수 ~50줄** — "한 화면에 들어오는가"의 대용치. 넘으면 대개 책임이 둘 이상이다. 정당한 예외: `parametrize` 케이스가 긴 테스트, CLI 옵션 정의, 쪼개면 흐름이 끊기는 순차 파이프라인
- **중첩 4단계** — 이건 예외가 거의 없다. early return·guard clause로 걷어낸다
- **파일 200–400줄** — 넘어가면 응집도를 재검토한다. 작은 파일 여럿 > 큰 파일 하나
- 모든 함수에 타입 힌트
- 높은 응집도, 낮은 결합도

## 체크리스트

- [ ] 프로젝트 ruff 설정을 확인했고 그쪽을 따랐다
- [ ] `ruff check --fix` · `ruff format` 통과
- [ ] `uv run ty check` 통과
- [ ] 제자리 변경 없음 (새 객체 반환)
- [ ] 에러 핸들링: 로그 + 사용자용 메시지
- [ ] 입력은 제약 붙은 Pydantic 모델로 검증
- [ ] 중첩 4단계 미만. 함수·파일이 임계값을 넘었다면 그럴 이유가 있다
- [ ] 모든 함수에 타입 힌트, `print()` 없음
