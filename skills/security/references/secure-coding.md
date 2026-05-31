# Secure Coding - Deep Dive (language-agnostic)

The "why" and "how" behind each section of the checklist. Concrete code is in [`js-ts.md`](js-ts.md) and [`python.md`](python.md).

---

## 1. Authentication

**Password storage.** Use a slow, salted hash: **argon2id** (preferred), **bcrypt**, or **scrypt**. Never MD5/SHA1/SHA256 alone - they're fast, which helps attackers. Never store plaintext or reversible encryption.

**Reset flow.** Generate a random, single-use token, store its **hash**, set a short expiry (15-60 min), email a link, invalidate on use. Don't reveal whether the email exists ("If that address is registered, we sent a link"). Same for login and signup - uniform timing and messaging prevent **user enumeration**.

**Brute force.** Throttle and lock after N failed attempts (exponential backoff or temporary lock). Add CAPTCHA after a threshold. Rate-limit at the IP and account level.

**MFA.** Offer TOTP/passkeys for sensitive accounts. Verify the second factor server-side.

## 2. Session management

Two token models:
- **Server sessions:** random opaque session ID in an httpOnly cookie; state stored server-side. Easy to revoke.
- **JWT:** stateless; **must** verify the signature and `exp`, and **reject `alg:none`** and algorithm-confusion (`RS256`->`HS256`). Keep no secrets/PII in the payload (it's only base64, not encrypted). Hard to revoke - keep lifetimes short and use refresh tokens.

Always **regenerate the session ID on privilege change/login** to prevent **session fixation** (attacker plants a known session ID, then rides it after you log in). Enforce idle + absolute timeouts. Invalidate on logout server-side (clearing the cookie alone isn't enough for JWT - use a denylist or short TTL).

## 3. Cookies

Set every auth cookie with:
- `HttpOnly` - JS can't read it, so XSS can't steal it.
- `Secure` - sent only over HTTPS.
- `SameSite=Lax` (or `Strict` for sensitive apps) - mitigates CSRF.
- Correct `Domain`/`Path` and a sensible `Max-Age`/`Expires`.

**Do not** put auth tokens in `localStorage` - any XSS reads it instantly. httpOnly cookies are the safer default.

## 4. Access control / authorization

The most common serious bug in vibe-coded apps. Authentication tells you *who* the user is; **authorization** decides whether they may act on *this specific resource*.

- **IDOR (Insecure Direct Object Reference):** `GET /api/orders/123` must check `order.userId === currentUser.id` (or org membership). Without it, incrementing the ID reads everyone's data.
- **Function-level checks:** admin endpoints must verify the role server-side - hiding the button isn't security.
- **Mass assignment:** never bind a whole request body to a model. Whitelist fields. Otherwise `{ "isAdmin": true, "balance": 9999 }` may just work.
- **Opaque IDs:** prefer UUIDs/ULIDs in URLs so resources can't be enumerated. (Still enforce ownership - opaque IDs are defense in depth, not a substitute.)
- **Open redirect:** never redirect to a user-supplied URL without allowlisting it.

## 5. Input & output handling

**Allowlist over blocklist.** Define what's *allowed* (e.g. `^[a-z0-9_]{3,20}$` for usernames) instead of trying to ban every bad thing. Blocklists always miss a case.

**Injection** = untrusted data interpreted as code/commands:
- **SQL/NoSQL:** use parameterized queries / prepared statements / an ORM's safe API. Never concatenate user input into a query string.
- **Command:** avoid shells; if unavoidable, pass args as an array and never interpolate input.
- **XSS:** encode output for its context (HTML, attribute, JS, URL). Frameworks auto-escape - the danger is `dangerouslySetInnerHTML` / `innerHTML` / `v-html`. Sanitize rich HTML with a vetted library (DOMPurify).
- **SSRF:** if the server fetches a user-supplied URL, allowlist hosts/schemes and block internal IP ranges (169.254.169.254 metadata, 127.0.0.1, 10/8, 192.168/16).
- **Path traversal:** canonicalize and confirm the resolved path stays inside the intended directory.
- **Deserialization:** never deserialize untrusted data into arbitrary objects (pickle, native Java/PHP serialization). Use JSON with a schema.

**CSRF:** for cookie-authenticated, state-changing requests, require an anti-CSRF token or rely on `SameSite` cookies + custom headers.

## 6. Data protection

- **In transit:** HTTPS everywhere; HSTS so browsers refuse plaintext.
- **At rest:** encrypt sensitive fields/columns; manage keys in a KMS; rotate.
- **Minimize:** the safest data is data you never stored.
- **Row-Level Security (RLS):** in multi-tenant apps (very common with Supabase/Postgres), enforce per-row access **in the database** with RLS policies. App-layer checks alone fail the moment one query forgets the `WHERE tenant_id = ?`. RLS makes the database refuse cross-tenant reads even if the app is buggy.
- **Don't overfetch:** select only the columns the client needs. `SELECT *` leaks password hashes and internal flags into API responses.

## 7. Error handling & logging

Users see a generic message and an error ID; the details go to your logs. Stack traces in production reveal stack, versions, file paths, and queries - a recon goldmine. Log **security-relevant events** (logins, privilege changes, admin actions, access to sensitive data) but **never log secrets, tokens, full card numbers, or passwords**. Beware **log injection** - newline characters in user input can forge log lines; encode them.

## 8. Secrets management

Secrets in the repo are the most-scanned leak on GitHub. Rules:
- `.env` and credential files in `.gitignore` from commit #1.
- Anything prefixed `NEXT_PUBLIC_`, `VITE_`, `REACT_APP_`, `EXPO_PUBLIC_` is **shipped to the browser** - never put real secrets there.
- Load secrets from a manager (Vault, AWS/GCP secret manager, platform env vars).
- Rotate on exposure; use distinct keys per environment.
- If a secret was ever committed, rotate it - removing it from HEAD doesn't remove it from history.

## 9. Configuration & operations

- **Least privilege everywhere:** the DB user the app connects as should not be a superuser; API keys should be scoped to what they need; the process shouldn't run as root; file permissions should be tight.
- **CORS:** never combine `Access-Control-Allow-Origin: *` with credentials. Allowlist specific origins.
- **Security headers:** CSP (biggest XSS mitigation), HSTS, `X-Frame-Options: DENY` (clickjacking), `X-Content-Type-Options: nosniff`, `Referrer-Policy`.
- **DoS / abuse:** rate-limit expensive and abusable endpoints (auth, reset, OTP, search, payment). Cap request body size and page size. Add timeouts. Avoid regexes with catastrophic backtracking (**ReDoS**) on user input.

## 10. Dependencies & supply chain

Most code in an app is third-party. Run `npm audit` / `pip-audit` / Dependabot. Pin versions and commit the lockfile so builds are reproducible and a hijacked transitive dependency can't silently change. Remove unused packages - less attack surface.

## 11. API & response hygiene

Correct status codes are both correctness and security:
- `200/201` success | `204` no content
- `400` malformed | `401` not authenticated | `403` authenticated but forbidden | `404` not found | `409` conflict | `422` validation failed | `429` rate-limited | `5xx` server error

Returning `200 {error: ...}` hides failures from clients and monitoring. Use `404` (not `403`) to avoid confirming a resource exists to someone who can't access it, where appropriate. Keep a consistent error envelope. Don't leak internal fields, SQL errors, or stack traces in the body. Check for broken links and redirect loops.

## 12. Forms & input UX (paired with server validation)

Good UX and security reinforce each other, but never confuse them:

> **Client validation is UX. Server validation is security. You need both, and the server must re-validate everything - it's the only gate an attacker can't skip.**

Recommended defaults (enforce in the form *and* in the API):
- Username **>= 3 chars**, allowlisted character set.
- Password **>= 9 chars**, with uppercase, lowercase, number, and symbol. (Length matters most - consider allowing passphrases and checking against breached-password lists.)
- **Confirm-password** must match.
- **Password visibility toggle** (eye icon) on password and confirm fields - reduces typos and lockouts.
- Inline, real-time feedback; disable submit until valid; block double-submit; show a strength meter.
- Trim whitespace; lowercase emails; normalize unicode.

A user can open dev tools or `curl` your endpoint and skip every client rule - so the backend independently rejects a 2-char username, a weak password, or a mismatched email.
