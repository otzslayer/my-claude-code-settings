# Security Guidelines

Standard practice (secrets in env, validated input, parameterized queries, XSS/CSRF, authz, rate limiting) is assumed; the hard prohibitions are in `boundaries.md` → Never → Security. This file holds only what neither covers.

## Secret Management

```python
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    api_key: str
    class Config:
        env_file = ".env"
```

## Security Issue Response

1. Stop immediately
2. Use **security-reviewer** agent
3. Fix CRITICAL issues first
4. Rotate exposed secrets
