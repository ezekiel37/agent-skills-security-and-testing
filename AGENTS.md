# AGENTS.md - agent-security-skills

This project ships two skills that make AI-generated code **secure** and **well-tested** by default. Read and apply them whenever you write, modify, or review application code.

## When to apply

- **Security skill** - any time you touch authentication, sessions, cookies, authorization, user input, database queries, API endpoints, file uploads, secrets/config, error handling, dependencies, or Next.js App Router / Server Components / Server Actions. Also when asked to "review for security", "audit", or "find vulnerabilities".
- **Testing skill** - any time you write or are asked about tests, or when you finish a feature. Also when asked "what edge cases am I missing", "make this robust", or "test this".

## Files to read

| Topic | File |
|---|---|
| Secure coding rules (12 sections) | `skills/security/SKILL.md` |
| Security audit checklist (run on existing code) | `skills/security/checklist.md` |
| Insecure-to-secure code (JS/TS) | `skills/security/references/js-ts.md` |
| Insecure-to-secure code (Python) | `skills/security/references/python.md` |
| Next.js App Router / RSC / Server Actions | `skills/security/references/nextjs.md` |
| Secure-coding deep dive | `skills/security/references/secure-coding.md` |
| Testing approach + taxonomy | `skills/testing/SKILL.md` |
| Test review checklist | `skills/testing/checklist.md` |
| Edge-case bank | `skills/testing/references/edge-cases.md` |
| Test code patterns (JS/TS) | `skills/testing/references/js-ts.md` |
| Test code patterns (Python) | `skills/testing/references/python.md` |

## Core rules (always)

1. **Validate on the server.** Client-side validation is UX only; it is bypassable. Re-validate everything on the backend.
2. **Prefer allowlists over blocklists.**
3. **Authorize every endpoint.** Authentication is not authorization. Check object ownership (no IDOR). In Next.js, authorize in a Data Access Layer, not in middleware or layouts.
4. **Never trust user input.** Parameterize queries. Encode output. Validate file uploads by content, not extension. Treat Server Action arguments as hostile.
5. **Run with least privilege** - scoped DB users, scoped API keys, minimal permissions.
6. **No secrets in source, client bundles, or logs.** Nothing real behind `NEXT_PUBLIC_`.
7. **Return correct HTTP status codes** and a consistent response shape.
8. **Test the unhappy path** - bad data, failures, abuse - not just success. Write a failing test before fixing a bug.
9. **Tests are code too** - review them; they are the last gate to production.
10. **Keep code maintainable** - readable and reviewable by a human later; no file anywhere near 1000+ lines; no duplication (DRY); no dead architecture or spaghetti. See `skills/security/checklist.md` ("Code maintainability").

Load the detailed files above for specifics and copy-pasteable examples.
