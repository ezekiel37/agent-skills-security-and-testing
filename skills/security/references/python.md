# Security Patterns - Python

Insecure-to-secure snippets for Django, FastAPI, and Flask. Principles are
framework-independent.

Setup with [uv](https://docs.astral.sh/uv/) (fast, modern Python tooling):

```bash
uv add argon2-cffi pydantic        # runtime deps
uv add slowapi                     # rate limiting for FastAPI
uv run python -m your_app          # run inside the project venv
```

Examples are marked `# Insecure` (do not ship) and `# Secure`.

---

## Password hashing

```python
# Insecure: fast, unsalted hash is brute-forceable
import hashlib
h = hashlib.sha256(password.encode()).hexdigest()

# Secure: argon2id (preferred)
from argon2 import PasswordHasher
ph = PasswordHasher()
hash_ = ph.hash(password)          # store this
ph.verify(hash_, password)         # raises on mismatch

# Django handles this for you:
from django.contrib.auth.hashers import make_password, check_password
```

## Input validation with Pydantic

```python
import re
from pydantic import BaseModel, EmailStr, field_validator

class Signup(BaseModel):
    username: str
    email: EmailStr
    password: str

    @field_validator("username")
    @classmethod
    def username_ok(cls, v: str) -> str:
        if not re.fullmatch(r"[A-Za-z0-9_]{3,20}", v):
            raise ValueError("3-20 letters, digits, or underscore")
        return v

    @field_validator("password")
    @classmethod
    def password_ok(cls, v: str) -> str:
        rules = [r"[A-Z]", r"[a-z]", r"\d", r"[^A-Za-z0-9]"]
        if len(v) < 9 or any(re.search(r, v) is None for r in rules):
            raise ValueError("min 9 chars with upper, lower, number, symbol")
        return v
# The server re-validates even when the frontend already did.
```

## SQL injection

```python
# Insecure: f-string into SQL
cur.execute(f"SELECT * FROM users WHERE email = '{email}'")

# Secure: parameterized query
cur.execute("SELECT id, email FROM users WHERE email = %s", (email,))

# Secure: ORM safe API. Never pass user input into raw()/extra() unparameterized.
User.objects.filter(email=email)                  # Django
session.query(User).filter(User.email == email)   # SQLAlchemy
```

## Authorization and IDOR

```python
# Insecure: returns any order by id
@app.get("/api/orders/{order_id}")
def get_order(order_id: str, user=Depends(current_user)):
    return db.get_order(order_id)          # any user reads any order

# Secure: enforce ownership; 404 avoids confirming the record exists
@app.get("/api/orders/{order_id}")
def get_order(order_id: str, user=Depends(current_user)):
    order = db.get_order(order_id)
    if order is None or order.user_id != user.id:
        raise HTTPException(status_code=404, detail="Not found")
    return order
```

## Mass assignment

```python
# Insecure: trusting the whole payload
user.__dict__.update(request.json)         # {"is_admin": true} slips in

# Secure: explicit fields via a schema
class ProfileUpdate(BaseModel):
    display_name: str
    bio: str | None = None

def update_me(data: ProfileUpdate, user=Depends(current_user)):
    db.update_user(user.id, display_name=data.display_name, bio=data.bio)
```

## Command injection

```python
import subprocess

# Insecure: shell=True with user input
subprocess.run(f"convert {filename} out.png", shell=True)

# Secure: pass args as a list, no shell
subprocess.run(["convert", filename, "out.png"], shell=False, check=True)
```

## SSRF

```python
import ipaddress, socket
from urllib.parse import urlparse
import requests

def safe_fetch(url: str):
    parsed = urlparse(url)
    if parsed.scheme != "https":
        raise ValueError("https only")
    ip = ipaddress.ip_address(socket.gethostbyname(parsed.hostname))
    if ip.is_private or ip.is_loopback or ip.is_link_local:
        raise ValueError("internal address blocked")  # blocks metadata IP, localhost, LAN
    return requests.get(url, timeout=5)
```

## Path traversal

```python
import os
BASE = "/srv/uploads"

# Secure: confirm the resolved path stays inside BASE
full = os.path.realpath(os.path.join(BASE, user_filename))
if not full.startswith(BASE + os.sep):
    raise ValueError("path traversal blocked")
```

## Unsafe deserialization

```python
import pickle

# Insecure: pickle on untrusted data is remote code execution
data = pickle.loads(request.body)

# Secure: JSON validated against a schema
data = Signup.model_validate_json(request.body)
```

## Secure cookies

```python
# FastAPI / Starlette
response.set_cookie(
    "session", token,
    httponly=True, secure=True, samesite="lax", max_age=604800, path="/",
)

# Django settings
SESSION_COOKIE_HTTPONLY = True
SESSION_COOKIE_SECURE = True
SESSION_COOKIE_SAMESITE = "Lax"
CSRF_COOKIE_SECURE = True
```

## Secrets

```python
import os

# Insecure: hardcoded secret
STRIPE_KEY = "sk_live_abc123"

# Secure: from the environment or a secrets manager, never committed
STRIPE_KEY = os.environ["STRIPE_SECRET_KEY"]   # .env is gitignored
```

## Rate limiting (FastAPI + slowapi)

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)

@app.post("/login")
@limiter.limit("10/15minutes")
def login(...): ...
```

## Correct status codes (FastAPI)

```python
raise HTTPException(401, "Not authenticated")   # who are you?
raise HTTPException(403, "Forbidden")           # known, but not allowed
raise HTTPException(404, "Not found")
raise HTTPException(409, "Already exists")
raise HTTPException(422, "Validation failed")   # FastAPI raises this for Pydantic errors
# Never return 200 with an error body.
```

## Row-Level Security (Postgres / Supabase)

```sql
-- Secure: the database enforces tenant isolation even if a query forgets WHERE
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON documents
  USING (tenant_id = current_setting('app.current_tenant')::uuid);

-- Supabase: scope rows to the authenticated user
CREATE POLICY "owner can read" ON documents
  FOR SELECT USING (auth.uid() = owner_id);
```

## Least-privilege database user

```sql
-- Insecure: the app connects as a superuser or table owner
-- Secure: a dedicated role with only what it needs
CREATE ROLE app_runtime LOGIN PASSWORD '...';
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_runtime;
-- no DROP, no DDL, no SUPERUSER
```
