---
name: security
description: Write secure application code by default and audit code for vulnerabilities. Use when working on authentication, sessions, cookies, authorization/access control, user input, database queries, API endpoints and status codes, file uploads, forms and validation, secrets/config, error handling, dependencies, or Next.js App Router / React Server Components / Server Actions - and when asked to "review for security", "audit", "find vulnerabilities", "is this secure", or harden an app. Covers the gaps AI-generated and vibe-coded apps usually miss.
---

# Security

Make application code secure **by default**, and audit existing code against a real checklist. This skill targets the gaps that AI-generated and "vibe-coded" apps almost always have: missing authorization, client-only validation, leaked secrets, wrong status codes, and unprotected endpoints.

Aligned with the SANS SWAT checklist and OWASP guidance, framed for people who don't know what they don't know.

## The three rules that prevent most breaches

1. **Validate on the server.** Client-side validation (the password rules in the form, the disabled submit button) is **UX only** - anyone can bypass it by calling your API directly. The backend must re-validate *everything*.
2. **Authorize every endpoint.** Authentication (who are you) is not authorization (are you allowed to touch *this* record). Check object ownership on every read and write, or users will read/edit each other's data (IDOR).
3. **Never trust input.** Parameterize queries, encode output, validate uploads by content. Treat every byte from a client as hostile.

## How to use this skill

- **While coding:** apply the rules below as you write. When you touch a topic, load the matching reference for concrete patterns.
- **Auditing:** load [`checklist.md`](checklist.md) and go section by section against the code, reporting findings with severity and a fix.
- **Need code:** load [`references/js-ts.md`](references/js-ts.md) or [`references/python.md`](references/python.md) for insecure->secure snippets. For Next.js App Router, React Server Components, and Server Actions, load [`references/nextjs.md`](references/nextjs.md). Load [`references/secure-coding.md`](references/secure-coding.md) for the full language-agnostic deep dive.

## The 12 sections (summary)

### 1. Authentication
Hash passwords with bcrypt/argon2 (never plaintext/MD5/SHA1). Strong password-reset (expiring single-use tokens, no user enumeration). Support MFA. Account lockout / throttling on brute force. Generic auth errors ("invalid email or password" - don't reveal which was wrong). Never hardcode credentials.

### 2. Session management
Random session IDs. **Regenerate the session token on login** (prevents session fixation). Idle + absolute timeouts. Invalidate server-side on logout. JWT: verify signature, reject `alg:none`, enforce expiry, keep no sensitive data in the payload.

### 3. Cookies
`HttpOnly` (blocks XSS theft) + `Secure` (HTTPS only) + `SameSite` (Lax/Strict). Correct domain/path scope and sensible expiry. Store tokens in httpOnly cookies, **not** `localStorage`.

### 4. Access control / authorization
Authorize **every** endpoint. Verify object ownership (no IDOR). Least privilege per role. **Mass-assignment protection** - whitelist bindable fields so a user can't set `isAdmin: true`. Use **opaque identifiers** (UUIDs) in URLs/APIs, not sequential DB IDs. No unvalidated redirects (open redirect). In **Next.js App Router**, do authorization in a Data Access Layer close to the data - *not* in middleware (bypassable, see CVE-2025-29927) or layouts (don't re-render on navigation). See [`references/nextjs.md`](references/nextjs.md).

### 5. Input & output handling
**Allowlist over blocklist.** Parameterized queries (SQL/NoSQL injection). No user input in shell `exec` (command injection). Contextual output encoding; avoid `dangerouslySetInnerHTML`. Sanitize rich HTML. SSRF - allowlist server-side fetch URLs. Path traversal - reject `../`. Safe deserialization. CSRF tokens on state-changing requests.

### 6. Data protection
HTTPS everywhere + HSTS. Encrypt sensitive data at rest; manage and rotate keys. Don't store data you don't need. **Row-Level Security (RLS)** on multi-tenant tables - enforce per-user/tenant isolation in the database, not just app code. No overfetching (never return password hashes / internal fields). No PII in logs.

### 7. Error handling & logging
Generic error messages to users; **no stack traces in production**. Handle all exceptions; suppress default framework error pages. Log authn, privilege changes, admin actions, and sensitive-data access. **Never log secrets/PII/tokens.** Store logs securely; monitor and alert.

### 8. Secrets management
No secrets in source or git history. `.env` gitignored. **No secrets in client bundles** (`NEXT_PUBLIC_*` and equivalents ship to the browser). Use a secrets manager / env injection. Separate keys per environment.

### 9. Configuration & operations
**Run with least privilege** - non-root DB user, scoped service accounts, minimal API-key scopes, restricted file permissions. Secure CORS (no `*` with credentials). Security headers: CSP, HSTS, X-Frame-Options, X-Content-Type-Options (nosniff). **DoS protection**: rate-limit login/signup/reset/OTP/payment; cap payload size and pagination; ReDoS-safe regex; request timeouts.

### 10. Dependencies & supply chain
Scan for known CVEs (`npm audit`, `pip-audit`). Pin versions + lockfile integrity. Remove unused dependencies.

### 11. API & response hygiene
**Correct HTTP status codes** - 200/201 success, 400 bad request, 401 unauthenticated, 403 forbidden, 404 not found, 409 conflict, 422 validation error, 429 rate-limited, 5xx server error. (Returning `200` with an error body hides failures and breaks clients.) Consistent response shape. No internal fields leaked. No broken links / dead URLs / redirect loops. Correct content-type headers.

### 12. Forms & input UX (security-paired)
Client validation is UX; the server is the gate - enforce **both**. Defaults this skill recommends:
- **Username >= 3 characters.**
- **Password >= 9 chars, with >=1 uppercase, >=1 lowercase, >=1 number, >=1 symbol.**
- **Confirm-password** field must match.
- **Password visibility toggle (eye icon)** on password and confirm-password fields.
- Inline real-time validation; disable submit until valid; prevent double-submit.
- Trim/normalize input (whitespace; lowercase emails).
- **The backend re-validates all of it** - these rules are bypassable from a direct API call.

## Severity guide (for audits)

- **Critical** - auth bypass, IDOR exposing other users' data, injection, secret in client/repo, RLS missing on multi-tenant data.
- **High** - missing rate limit on auth/payment, sensitive data in logs, weak password hashing, CSRF on money-moving actions.
- **Medium** - wrong status codes, missing security headers, verbose errors, weak validation.
- **Low** - missing nice-to-haves (password toggle, inline validation), minor hardening.

Report each finding as: **what** (the risk), **where** (file:line), **why it matters**, **fix** (concrete).
