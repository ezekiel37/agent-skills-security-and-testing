# agent-security-skills (Antigravity / Gemini rules)

Make generated code secure and well-tested by default. Apply when writing, modifying, or reviewing application code. Full content is in the `skills/` folder - read those files for depth and copy-pasteable examples.

## Security - always

- **Validate on the server.** Client-side validation is UX only and is bypassable. Re-validate everything in the backend.
- **Allowlist over blocklist.** Validate against known-good values.
- **Authorize every endpoint.** Authentication is not authorization. Verify object ownership to prevent IDOR. In Next.js, authorize in a Data Access Layer, not in middleware or layouts.
- **Never trust input.** Parameterized queries. Encode output. Validate uploads by content (magic bytes), not extension. Treat Server Action arguments as hostile.
- **Least privilege.** Scoped DB users and API keys; minimal permissions. Row-Level Security on multi-tenant tables.
- **Secrets** never in source, git history, client bundles, or logs. Nothing real behind `NEXT_PUBLIC_`.
- **API hygiene.** Correct HTTP status codes, consistent response shape, no internal fields leaked.
- **Forms.** Username >= 3 chars; password >= 9 chars with upper/lower/number/symbol; confirm-password match; visibility toggle - enforced client AND server.

## Testing - always

- Test that it works, that it fails gracefully on bad/unexpected input, and that it can't be abused.
- Cover edge cases (empty/null, boundaries, unicode, timezones, network failure, concurrency, payments, webhooks).
- Assert HTTP status codes and response schemas.
- Write a failing test before fixing a bug.
- Tests are code - review them; they are the last gate to production.

## Reference files

- Security: `skills/security/SKILL.md`, `skills/security/checklist.md`, `skills/security/references/*` (incl. `nextjs.md`)
- Testing: `skills/testing/SKILL.md`, `skills/testing/checklist.md`, `skills/testing/references/*`
