# Security Audit Checklist

Run this against existing code section by section. For each item: confirm it's handled, or report a finding with **file:line | severity | fix**. Severity guide is at the bottom of [`SKILL.md`](SKILL.md).

> Remember the three rules: **validate on the server**, **authorize every endpoint**, **never trust input**.

## 1. Authentication
- [ ] Passwords hashed with bcrypt/argon2/scrypt (never plaintext, MD5, SHA1)
- [ ] No hardcoded credentials or API keys in source
- [ ] Strong password policy enforced **server-side**
- [ ] Password reset uses expiring, single-use tokens
- [ ] Reset/login flows don't reveal whether an account exists (no enumeration)
- [ ] Account lockout or throttling on repeated failed logins
- [ ] MFA available for sensitive accounts
- [ ] Generic auth error messages ("invalid email or password")
- [ ] Email/identity verified before granting access

## 2. Session management
- [ ] Session IDs are cryptographically random
- [ ] Session token **regenerated on login** (no session fixation)
- [ ] Idle timeout AND absolute timeout enforced
- [ ] Session invalidated server-side on logout
- [ ] JWT signature verified; `alg:none` rejected
- [ ] JWT expiry enforced; no sensitive data in payload
- [ ] Concurrent-session and "logged out elsewhere" behavior defined

## 3. Cookies
- [ ] `HttpOnly` set on session/auth cookies
- [ ] `Secure` set (HTTPS only)
- [ ] `SameSite` set (Lax or Strict)
- [ ] Correct domain/path scope and expiry
- [ ] Auth tokens in httpOnly cookies, not `localStorage`/`sessionStorage`

## 4. Access control / authorization
- [ ] Every endpoint checks authorization, not just authentication
- [ ] Object ownership verified on read/update/delete (no IDOR)
- [ ] Role/permission checks on admin and sensitive actions
- [ ] Mass-assignment protection (bindable fields whitelisted; `isAdmin` etc. not settable)
- [ ] Opaque identifiers (UUIDs) in URLs/APIs, not sequential DB IDs
- [ ] No unvalidated forwards/redirects (open redirect)
- [ ] Authorization enforced server-side, not by hiding UI

## 5. Input & output handling
- [ ] Allowlist validation (known-good), not blocklist
- [ ] Validation happens on the **server** (not client-only)
- [ ] Parameterized queries everywhere (no string-concatenated SQL/NoSQL)
- [ ] No user input passed to shell/`exec` (command injection)
- [ ] Output contextually encoded; no raw HTML injection (`dangerouslySetInnerHTML`, `innerHTML`)
- [ ] Rich/HTML content sanitized (e.g. DOMPurify)
- [ ] Server-side fetch URLs validated/allowlisted (SSRF)
- [ ] File paths canonicalized; `../` rejected (path traversal)
- [ ] Untrusted data deserialized safely
- [ ] Prototype pollution guarded (JS)
- [ ] CSRF protection on state-changing requests
- [ ] File uploads validated by content (magic bytes), size-limited, stored outside webroot, served with `nosniff`

## 6. Data protection
- [ ] HTTPS everywhere; HSTS enabled
- [ ] Sensitive data encrypted at rest
- [ ] Key management and rotation in place
- [ ] Minimal data retention (don't store what you don't need)
- [ ] Row-Level Security on multi-tenant tables (DB-enforced isolation)
- [ ] APIs don't overfetch (no password hashes, internal fields in responses)
- [ ] No PII or secrets written to logs

## 7. Error handling & logging
- [ ] Generic error messages to users; no stack traces in prod
- [ ] All exceptions handled; framework default error pages suppressed
- [ ] Security events logged (authn, privilege change, admin, sensitive-data access)
- [ ] Secrets/PII/tokens never logged
- [ ] Logs stored securely; monitoring/alerting exists

## 8. Secrets management
- [ ] No secrets in source or git history (check history, not just HEAD)
- [ ] `.env` and secret files gitignored
- [ ] No secrets in client bundles (`NEXT_PUBLIC_*`, `VITE_*`, `REACT_APP_*` etc.)
- [ ] Secrets loaded from a manager / injected env, not committed config
- [ ] Separate credentials per environment

## 9. Configuration & operations
- [ ] App runs with least privilege (non-root DB user, scoped keys, restricted file perms)
- [ ] CORS not `*` with credentials; origins allowlisted
- [ ] Security headers present (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- [ ] Rate limiting on login, signup, password reset, OTP, payment
- [ ] Payload size caps; pagination caps; request timeouts
- [ ] Regexes are ReDoS-safe (no catastrophic backtracking on user input)
- [ ] CI/CD pipeline and infra hardened; incident plan exists

## 10. Dependencies & supply chain
- [ ] No known-CVE dependencies (`npm audit` / `pip-audit` clean or triaged)
- [ ] Versions pinned; lockfile committed
- [ ] Unused dependencies removed

## 11. API & response hygiene
- [ ] Correct HTTP status codes (not `200` for errors)
- [ ] 401 vs 403 used correctly (unauthenticated vs forbidden)
- [ ] 422/400 for validation, 409 for conflicts, 429 for rate limit
- [ ] Consistent response/error envelope
- [ ] No internal/sensitive fields leaked in responses
- [ ] No broken links, dead URLs, or redirect loops
- [ ] Correct content-type headers

## 12. Forms & input UX (enforce client AND server)
- [ ] Username >= 3 characters
- [ ] Password >= 9 chars with uppercase, lowercase, number, symbol
- [ ] Confirm-password matches password
- [ ] Password visibility toggle (eye icon) on password + confirm fields
- [ ] Inline/real-time validation feedback
- [ ] Submit disabled until valid; double-submit prevented
- [ ] Input trimmed/normalized (whitespace; emails lowercased)
- [ ] **All of the above re-validated on the backend**

## 13. Next.js App Router / RSC (if applicable)
- [ ] Auth verified in a Data Access Layer / data functions, not only middleware or layouts
- [ ] `import "server-only"` on data-access and secret-reading modules
- [ ] Client Component props carry minimal fields, not whole records
- [ ] Every Server Action validates its arguments AND re-authorizes the user
- [ ] `route.ts` handlers authenticate, authorize, and handle CSRF
- [ ] `params` / `searchParams` re-verified, never trusted for authorization
- [ ] No real secrets behind `NEXT_PUBLIC_`
- [ ] Next.js and React pinned and patched against known CVEs

(Full detail and code in [`references/nextjs.md`](references/nextjs.md).)

## Negative tests to actually try
- [ ] Call an authenticated API without/with another user's token -> blocked?
- [ ] Request another user's record by ID -> blocked?
- [ ] Send `isAdmin:true` / extra fields in a body -> ignored?
- [ ] Send `qty: -5`, huge numbers, or negative totals -> rejected?
- [ ] Replay a one-time action (coupon, payment) -> blocked (idempotent)?
- [ ] Bypass client validation by hitting the API directly -> server rejects?
- [ ] Upload a disguised/oversized file -> rejected?
- [ ] Tamper with JWT claims / hidden fields -> detected?

## Code maintainability (review the code itself, not just security)
- [ ] **Readable** - clear names, consistent style, obvious control flow; a new dev can follow it
- [ ] **Maintainable** - a human can revisit, review, and change it later without fear
- [ ] **No giant files** - nothing anywhere near 1000+ lines; split by responsibility
- [ ] **No duplication** - shared logic is factored out, not copy-pasted (DRY)
- [ ] **No dead architecture** - no unused code, dead branches, orphaned modules, or abandoned abstractions
- [ ] **No spaghetti** - functions do one thing; dependencies flow one direction; no tangled cross-calls
- [ ] **Right altitude** - not over-engineered for the need, not under-structured for the scale
