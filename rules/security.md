# Security Guidelines

## Pre-Commit Checklist

- [ ] No hardcoded secrets
- [ ] All user inputs validated
- [ ] SQL injection prevention
- [ ] XSS prevention
- [ ] CSRF protection enabled
- [ ] Auth/authz verified
- [ ] Rate limiting on endpoints
- [ ] Error messages don't leak sensitive data

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
