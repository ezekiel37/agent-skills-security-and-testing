# Testing Guide - Taxonomy & Strategy

The mental model behind the testing skill, for when you need to decide *what kind* of test to write and *where* it belongs.

---

## Testing levels (scope of what's under test)

| Level | Scope | Example |
|---|---|---|
| **Unit** | One function/module in isolation | `calculateTax(99.99, 'CA')` returns the right cents |
| **Integration** | Several units + a real boundary (DB, API) | "create order" writes the row and decrements stock |
| **System** | The whole app end-to-end in a real-ish env | full checkout via the HTTP API |
| **Acceptance** | Does it meet the requirement / user need | "a user can buy a product and get a receipt" |

## Functional test types

- **Smoke** - does the build even run? A handful of critical paths. Run first.
- **Sanity** - narrow check that a specific fix/area works.
- **Regression** - re-run existing tests to confirm new changes didn't break old behavior.
- **e2e / UI** - drive the real UI through a user journey (Playwright/Cypress).

## Non-functional test types

- **Performance** - latency/throughput under expected load.
- **Load** - behavior at expected peak.
- **Stress** - behavior beyond peak; where/how it breaks.
- **Scalability** - does adding resources help?
- **Usability** - can a real person accomplish the task?
- **Compatibility** - browsers, devices, OS versions.
- **Security** - the negative/abuse tests (see the security skill).
- **Accessibility** - keyboard, screen reader, contrast (see edge-cases.md).

## Approaches

- **Manual vs automated** - automate anything you'll run more than a few times.
- **Black / white / grey box** - test by behavior only / with knowledge of internals / a mix.
- **Static vs dynamic** - analyze code without running it (linters, type checkers, SAST) vs run it.
- **Shift-left** - test early and continuously, not just before release. Cheaper to fix early.
- **TDD** - write the failing test first, then code to pass it.
- **BDD** - describe behavior in given/when/then; tests double as living spec.

## The test pyramid

```
        /\        e2e        few   - slow, flaky, expensive; critical journeys only
       /  \
      /----\     integration  some - real DB/API boundaries
     /      \
    /--------\   unit          many - fast, isolated, pure logic
```

Invert this (mostly e2e) and your suite becomes slow and flaky - the "ice-cream cone" anti-pattern. Most assertions belong in unit tests; reserve e2e for a few money paths.

## What to test (and what not to)

**Do test:** business logic, validation rules, calculations (money, dates), state transitions, error/failure handling, authorization boundaries, regressions, the API contract (status + shape).

**Don't bother testing:** the framework itself, the language, third-party libraries, trivial getters/setters, or private implementation details. Don't write a snapshot test of an entire page and call it coverage.

## Core principles

1. **Test behavior, not implementation.** Assert observable outputs. If a refactor that preserves behavior breaks your test, the test was coupled to internals.
2. **Determinism.** Inject the clock, seed RNG, mock network/time, isolate DB state per test. Flaky tests get muted and then everything gets muted.
3. **Regression first.** Reproduce a bug with a failing test *before* fixing it. The test proves the fix and guards forever.
4. **Arrange-Act-Assert.** One clear behavior per test; a descriptive name; ideally one logical assertion.
5. **Coverage is a signal.** Aim for meaningful branch/failure-path coverage, not a vanity percentage.
6. **Tests are code.** Review them. No assertion-free tests, no leftover `.only`/`.skip`, no tautologies.

## Quick recipe for any feature

1. Happy path (unit + one integration).
2. Each validation rule rejects bad input (unit).
3. Empty/null/boundary inputs (unit).
4. One failure path - dependency down/timeout (integration, mocked).
5. One authorization test - other user blocked (integration).
6. Idempotency for money/state changes (integration).
7. A regression test for any bug you're fixing.
8. One e2e for the whole journey if it's a critical path.
