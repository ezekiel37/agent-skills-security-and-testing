---
name: testing
description: Test application code beyond the happy path - edge cases, failure paths, and abuse. Use when writing or reviewing tests, when finishing a feature, or when asked "what edge cases am I missing", "make this robust", "test this", "is this well tested", or for help with unit/integration/e2e tests, mocking, flaky tests, or test strategy. Includes a ~220-item edge-case bank and per-stack examples (JS/TS, Python).
---

# Testing

Test the way production actually fails. AI-generated and vibe-coded apps get the happy path tested (if at all) and ship every bad-input, failure, and abuse case untested - which is exactly where real bugs live.

## The framing (apply this to everything)

> Test that users *can* use the app - they can log in and save an object. Equally, test that the app *doesn't break* when bad data or unexpected actions happen: a typo, an incomplete form, the wrong API call. Test that data *can't be compromised* and that no one can reach a resource they shouldn't. **A good test suite tries to break your app and reveals its limits.**
>
> And finally - **tests are code too.** Review them; they may be the final gate to production.

So for any feature, write three kinds of tests:
1. **It works** - the happy path produces the right result.
2. **It fails gracefully** - bad/missing/unexpected input is rejected with a clear error, not a crash or corrupt state.
3. **It can't be abused** - authorization holds, limits are enforced, actions are idempotent.

## How to use this skill

- **Writing tests for a feature:** cover all three kinds above. Pull relevant categories from [`references/edge-cases.md`](references/edge-cases.md) - the ~220-item bank, grouped by domain.
- **Reviewing tests / a PR:** run [`checklist.md`](checklist.md).
- **Need test code:** [`references/js-ts.md`](references/js-ts.md) (Vitest/Jest/Playwright) or [`references/python.md`](references/python.md) (pytest).
- **Strategy / taxonomy questions:** [`references/testing-guide.md`](references/testing-guide.md).

## Taxonomy (the mental model)

- **Levels:** Unit -> Integration -> System -> Acceptance.
- **Functional types:** smoke, sanity, regression, e2e/UI.
- **Non-functional types:** performance, load, stress, scalability, usability, compatibility, security, accessibility.
- **Approaches:** manual vs automated | black/white/grey box | static vs dynamic | shift-left | TDD/BDD.

## The test pyramid (what to put where)

- **Many unit tests** - pure logic, validation, calculations. Fast, isolated, no I/O.
- **Fewer integration tests** - modules + real DB/API boundaries; auth, persistence, transactions.
- **Few e2e tests** - critical user journeys only (signup, checkout). Slow and flakier; don't test everything here.

Anti-pattern: an "ice-cream cone" (mostly slow e2e, few unit) - slow, flaky, expensive.

## Principles that matter most

- **Test behavior, not implementation.** Assert what the user/caller observes, not private internals - so refactors don't break tests.
- **Regression discipline.** When you fix a bug, first write a test that reproduces it (fails), then fix it (passes). That bug never comes back silently.
- **Deterministic tests.** No real time/random/network/order dependence. Inject the clock, seed randomness, mock external calls, isolate state between tests. Flaky tests get ignored, which defeats the point.
- **Coverage is a signal, not a goal.** 100% of trivial getters proves nothing; one good edge-case test on payment logic is worth more. Chase *meaningful* coverage of branches and failure paths.
- **Know what NOT to test.** Don't test the framework, the language, or third-party libraries. Don't assert on implementation details. Don't write brittle snapshot tests of everything.
- **Assert the contract.** For APIs, assert **status code AND response shape**, not just the body - a `200` with the wrong shape is still a bug.
- **Tests are reviewed code.** A test with no assertion, a wrong assertion, or a disabled (`skip`/`only`) line is worse than no test. Review them like production code.

## Minimum bar for "well tested" (per feature)

- [ ] Happy path
- [ ] Each validation rule rejects bad input (with the right status/error)
- [ ] Empty/null/missing inputs
- [ ] At least one boundary (first/last/limit +/- 1)
- [ ] One failure path (dependency down / timeout)
- [ ] One authorization test (other user can't access)
- [ ] Idempotency for any money/state-changing action
- [ ] A regression test for every bug fixed here

Load [`references/edge-cases.md`](references/edge-cases.md) and pick the categories that apply to the feature in front of you.
