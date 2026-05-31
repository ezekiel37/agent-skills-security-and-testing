# Test Review Checklist

Run this when reviewing tests or a PR. Tests are code - a wrong, missing, or disabled assertion is worse than nothing.

## Coverage of the three lenses
- [ ] **Happy path** - core flow produces the right result
- [ ] **Fails gracefully** - bad/missing/unexpected input -> clear error, no crash, no corrupt state
- [ ] **Can't be abused** - authorization, limits, idempotency tested

## Inputs
- [ ] Empty / null / undefined / missing fields
- [ ] Boundaries - min, max, first, last, limit +/- 1
- [ ] Zero, negative, very large numbers; float precision where money is involved
- [ ] Unicode / emoji / very long / whitespace-only strings
- [ ] Wrong types / malformed input
- [ ] Dates: timezones, DST, leap year, end-of-month (if dates are used)

## Failure paths
- [ ] Dependency down (DB / external API)
- [ ] Timeout / slow response
- [ ] Malformed or empty response from a dependency
- [ ] Partial failure + retry + idempotency
- [ ] Errors surface clearly (right message / right status code)

## API contract
- [ ] Asserts **status code** (not just body)
- [ ] Asserts **response shape/schema**
- [ ] 401 vs 403 vs 404 vs 422 vs 409 vs 429 distinguished correctly

## Security-minded tests
- [ ] Another user cannot read/modify this resource (IDOR)
- [ ] Invalid/expired auth is rejected
- [ ] Injection/XSS payloads handled safely
- [ ] Limits enforced (rate limit, payload size, negative quantity)
- [ ] Client validation also enforced server-side (hit API directly)

## State & concurrency (if applicable)
- [ ] Double-submit / race / concurrent writes
- [ ] Pagination boundaries
- [ ] UI loading / error / **empty** states (not just success)

## Test quality
- [ ] Tests assert **behavior**, not implementation details
- [ ] **Deterministic** - no real time/random/network/order dependence
- [ ] External dependencies mocked; state isolated between tests
- [ ] No `.only` / `.skip` / commented-out / assertion-free tests left in
- [ ] A **regression test exists for every bug fixed** in this change
- [ ] Right level used (unit vs integration vs e2e) per the pyramid
- [ ] Coverage is meaningful (branches/failure paths), not vanity %

## Smells to flag
- [ ] Test with no assertion
- [ ] Test that always passes (tautology)
- [ ] Snapshot test of everything (brittle)
- [ ] Over-mocking that tests the mock, not the code
- [ ] Flaky test (passes/fails on re-run) - fix or quarantine, don't ignore

## Code maintainability (the code under test, too)
- [ ] Readable and maintainable - a human can revisit and review it later
- [ ] No file anywhere near 1000+ lines; no duplication; no dead architecture or spaghetti

(Full maintainability checklist in [`../security/checklist.md`](../security/checklist.md).)
