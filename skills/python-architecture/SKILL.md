---
name: python-architecture
description: "Python project Layered Architecture (interface / services / repositories / models / core). Use when: (1) starting a new Python project (CLI, data pipeline, library, MCP server, service), (2) scaffolding directory structure for Python code, (3) deciding where a new Python module should go, (4) refactoring Python project layout, (5) reviewing dependency direction violations between layers. NOT for FastAPI projects (use fastapi-project-structure instead)."
---

# Python Layered Architecture (MANDATORY)

All Python projects (non-FastAPI) MUST use Layered Architecture.
For FastAPI projects, follow the `fastapi-project-structure` skill instead.

## Scope

- **Apply to**: CLI tools, data pipelines, script collections, libraries, services, MCP servers, etc.
- **Exempt**: Single-file scripts (under 50 lines), one-off utilities

## Standard Directory Structure

```
myproject/
├── src/
│   └── myproject/
│       ├── __init__.py
│       ├── main.py              # Entry point (minimal code)
│       ├── interface/           # I/O layer (CLI, events, external interfaces)
│       │   ├── __init__.py
│       │   └── cli.py           # Typer/Click CLI, etc.
│       ├── services/            # Business logic layer
│       │   ├── __init__.py
│       │   └── example.py       # Pure business rules
│       ├── repositories/        # Data access layer
│       │   ├── __init__.py
│       │   └── example.py       # DB/file/external API access
│       ├── models/              # Domain models (Pydantic/dataclass)
│       │   ├── __init__.py
│       │   └── example.py
│       └── core/                # Cross-cutting concerns
│           ├── __init__.py
│           ├── config.py        # Pydantic Settings
│           ├── logging.py       # Logger setup
│           └── exceptions.py    # Custom exceptions
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── pyproject.toml
└── .env.example
```

## Layer Responsibilities

| Layer | Responsibility | Dependency Direction |
|-------|---------------|----------------------|
| `interface/` | Receive external input → call services | Depends on services only |
| `services/` | Business rules, use-case orchestration | Depends on repositories, models |
| `repositories/` | Data store access, queries | Depends on models |
| `models/` | Domain entities, value objects | No dependencies on other layers |
| `core/` | Config, logging, exceptions — used by all layers | Minimal dependencies |

## Dependency Rule

```
interface → services → repositories → models
              ↓              ↓
            core           core
```

- Upper layers call lower layers only (no reverse direction)
- `repositories` must not know about `interface`
- `services` depend on repository interfaces, not implementations

## Scaling Down by Project Size

Layers may be merged for smaller projects:

**Small (simple tools):**
```
myproject/
├── src/myproject/
│   ├── __init__.py
│   ├── main.py
│   ├── service.py     # services + repositories combined
│   ├── models.py
│   └── core/
```

**Medium (standard):** Use the full structure above

**Large (expanded):** Split into domain packages
```
myproject/
├── src/myproject/
│   ├── auth/          # Domain package (each with services/, repos/)
│   ├── billing/
│   └── core/
```

## Scaffolding Checklist

When starting a new Python project:
- [ ] Use src/ layout
- [ ] Create interface/, services/, repositories/, models/, core/ directories
- [ ] Configure `[tool.pytest.ini_options]` in pyproject.toml
- [ ] Set up Pydantic Settings in core/config.py
- [ ] Define custom exceptions in core/exceptions.py
- [ ] Create .env.example
- [ ] Separate tests/unit/ and tests/integration/

## On Violation

When tempted to add code without proper structure:
1. Create the layer structure first
2. Place code in the appropriate layer
3. Verify dependency direction before proceeding
