# Security Guidelines

Security rules (secrets, input validation, SQL, XSS/CSRF, auth, rate limiting) live in `boundaries.md` → Security. This file holds only what boundaries doesn't.

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
