# The Edge-Case Bank

Edge cases AI-generated and vibe-coded apps usually miss, grouped by domain. Each
item has a short "why it breaks". For a feature, scan the relevant sections and
write tests for the ones that apply.

> Three lenses for every input: **does it work**, **does it fail gracefully**,
> **can it be abused**.

The **core domains** every app should cover: Numbers, Strings, Dates/Time,
Collections, Network, Auth, Files, Forms, State. The rest apply when your app has
that surface (payments, websockets, maps, mobile, Next.js/RSC, etc.).

---

## Numbers and math
- **Zero** - division, "0 results", falsy-vs-valid-zero bugs.
- **Negative** - quantities, balances, indexes that should not go below 0.
- **Very large / overflow** - beyond `MAX_SAFE_INTEGER`; counters, IDs, sums.
- **Float precision** - `0.1 + 0.2 !== 0.3`; never use floats for money.
- **Rounding** - half-up vs banker's; tax, discounts, splitting a bill.
- **Division/modulo by zero** - crash or `Infinity`/`NaN`.
- **NaN / Infinity / -Infinity** - propagate silently through calculations.
- **Leading zeros, signs, scientific notation** (`007`, `+5`, `1e10`) - parsing surprises.
- **Currency** - store integer cents/decimals, not floats; rounding on conversion.

## Strings and text
- **Empty / whitespace-only** - a "required" field with only spaces passes naive checks.
- **Very long** (10k+ chars) - layout break, DB column overflow, DoS.
- **Single character / minimum length** - boundary.
- **Unicode and emoji** - multi-byte length (`"a".length` lies for combined emoji), truncation splits a grapheme.
- **RTL text** (Arabic/Hebrew) - layout and concatenation.
- **Accents / normalization** - the same character as one vs two code points (NFC/NFD); search misses.
- **Case sensitivity** - `A@x.com` vs `a@x.com`; usernames, lookups.
- **Special/injection chars** - `<script>`, `'; DROP`, `{{7*7}}`, `../`.
- **Newlines, tabs, null bytes, zero-width chars** - log injection, broken parsing.
- **Homoglyphs** - Cyrillic and Latin look-alikes in usernames/domains (spoofing).

## Dates, time, and timezones
- **Timezones** - store UTC, display local; "off by a day" near midnight.
- **DST transitions** - the spring-forward hour that does not exist; the fall-back hour that happens twice.
- **Leap year** - Feb 29; age/anniversary math.
- **End-of-month** - Jan 31 + 1 month = ? ; recurring billing.
- **Midnight / "today"** - depends on the user's timezone, not the server's.
- **Past/future invalid** - birthdate in the future, expiry in the past.
- **Format ambiguity** - `03/04` is March 4 or April 3? Locale-dependent.
- **Epoch 0 / year 2038** - 32-bit timestamp overflow.
- **Duration across DST** - "24 hours later" is not "same time tomorrow".

## Collections and pagination
- **Empty list** - render an empty state, not a crash or blank.
- **Single item** - "1 items" grammar, layout.
- **Exactly page-size / +-1** - off-by-one on the last page.
- **Page beyond range / page 0 / negative page** - clamp or error.
- **Duplicates** - dedupe expectations.
- **Sorting with ties / nulls** - stable order? nulls first or last?
- **Very large list** - performance, needs virtualization/pagination.
- **Concurrent modification** - item added/removed while iterating or paginating.

## Network and async
- **Timeout** - no response; must time out, not hang forever.
- **Slow (3G)** - loading states, no double-trigger.
- **Offline / intermittent** - queue, retry, or fail clearly.
- **Double-fire** - a double-click submits twice (idempotency).
- **Out-of-order responses** - request A returns after request B (stale render).
- **5xx / malformed JSON / empty response** - do not assume a valid body.
- **Retry storms** - need exponential backoff + jitter.
- **Connection dropped mid-request** - partial upload/download.
- **Stale data after reconnect** - refetch / reconcile.

## Auth and session
- **Token expires mid-session** - graceful refresh, not a hard crash.
- **Token refresh race** - two requests refresh at once.
- **Logged out in another tab** - current tab still thinks it is authed.
- **Concurrent sessions** - multiple devices.
- **Permissions changed mid-session** - was admin, now is not.
- **Account deleted/banned while logged in** - next action should fail cleanly.
- **Email changed, old session active**.
- **Deep-link to a protected page while logged out** - redirect to login, then back.

## Files and uploads
- **0-byte file**, **exactly-at-limit**, and **over-limit** - boundaries.
- **Wrong type disguised** - `.exe` renamed `.jpg`; check magic bytes, not extension.
- **No extension / double extension** (`x.php.jpg`).
- **Unicode / special chars / path traversal in filename**.
- **Corrupt / truncated file** - partial decode.
- **Filename collisions** - two users upload `photo.jpg`.
- **Simultaneous uploads / cancel mid-upload**.

## Forms and user input
- **Submit empty / incomplete** - every required field missing.
- **Submit twice** (double-click, back-then-resubmit) - duplicate record.
- **Required field with only spaces** - trim before validating.
- **Max-length behavior** - silent truncation vs error.
- **Paste vs type / autofill** - events may not fire as expected.
- **Copy-pasted formatted text / hidden characters**.
- **Refresh mid-form** - data loss; warn on unsaved changes.
- **Navigate away with unsaved changes** - prompt.
- **Keyboard-only / tab order** - accessibility and completion.
- **Confirm-password mismatch / weak password / short username** - rejected client AND server.

## Search and filters
- **No results / one result / thousands** - each renders correctly.
- **Special chars / regex metacharacters in query** - no crash, no injection.
- **Empty / whitespace / very long query**.
- **Case- and accent-insensitive** expectations.
- **Combined filters yield an empty set** - clear "no matches".
- **Debounce** - fast typing then clear; last query wins.

## State and data integrity
- **Concurrent edits** - two users save the same record (last-write-wins vs conflict).
- **Idempotency** - pay/submit/order twice yields one result.
- **Partial save / transaction rollback** - all-or-nothing.
- **Cascading deletes** - delete user, then orphaned rows or broken FKs.
- **Stale references** - item deleted while in someone's cart/open tab.
- **Optimistic locking / version conflict** - detect overwrites.

## Browser, device, and environment
- **Mobile vs desktop / small screens / orientation**.
- **Slow device / low memory**.
- **JS disabled / ad-blocker / cookies disabled / localStorage full**.
- **Back/forward / refresh / multiple tabs / deep links**.
- **Browser differences** (Safari date quirks), **zoom 200%**.
- **Dark mode / reduced-motion / screen reader**.

## Internationalization
- **Longer translations** - German is roughly 2x English; layout overflow.
- **Locale formatting** - number, currency, date per locale.
- **Pluralization / gendered languages** - "1 item" vs "2 items" vs Slavic plural rules.
- **Name formats** - single name, multiple surnames, non-Latin scripts.
- **Address / phone / postal formats** per country.

## System and boundary
- **First run / empty database / no seed data** - empty states everywhere.
- **Resource exhaustion** - disk full, quota/rate limit hit.
- **Clock skew** - client vs server time disagree.
- **Cold start / cache miss vs hit**.
- **Migration with existing data** - old rows missing new columns.
- **Feature flag toggled mid-flow**.

## Payments and financial
- **Card declined / insufficient funds / expired mid-transaction**.
- **Double-charge / duplicate payment** - use idempotency keys.
- **Payment succeeds but the webhook never arrives** - reconciliation job.
- **Refund > original / partial refund / refund after dispute**.
- **Currency conversion rounding / multi-currency cart**.
- **Subscription lifecycle** - trial to paid, downgrade mid-cycle, proration, failed renewal, dunning.
- **Tax/VAT by region / discount stacking / negative total from over-discount**.
- **Chargeback** and **pay in one currency, payout in another**.

## Email, SMS, and notifications
- **Invalid / disposable email / bounced / full inbox**.
- **Plus-addressing** (`user+tag@x.com`) and **unicode domains**.
- **Unsubscribed but transactional still sends** (allowed) vs marketing (not).
- **Duplicate notifications / notification storm**.
- **Wrong timezone for scheduled sends**.
- **SMS to a landline / international format / opt-out (STOP)**.
- **Deep link in an email opens the wrong app state / expired link**.

## Real-time, websockets, and live
- **Connection drop + reconnect** - resume vs restart.
- **Out-of-order / duplicate messages**.
- **Two users editing the same doc** - conflict resolution / CRDT.
- **Presence** - ghost users, stale "online".
- **Backpressure** - messages faster than the client can render.
- **Missed events while disconnected** - catch-up/replay on reconnect.

## Geolocation and maps
- **Permission denied / unavailable / low accuracy**.
- **Antimeridian (+-180 longitude) and poles** - wrap-around math.
- **Crossing timezone / country borders**.
- **Distance across hemispheres** - sign errors.
- **Mock/spoofed location / stale cached location**.

## Third-party integrations and webhooks
- **API down / rate-limited / unexpected schema** (breaking change).
- **API key expired/revoked mid-use**.
- **Webhook: duplicate delivery, out-of-order, invalid signature, replay**.
- **Webhook arrives before your DB write commits** - race; retry/lookup.
- **OAuth: user revokes access, token expires, scope changed**.
- **Slow third-party blocking your request** - timeout + circuit breaker.
- **Sandbox vs production credential mixup**.

## Database-specific
- **Unique-constraint race** - "check then insert" between two requests.
- **Foreign-key violation / cascading delete surprises**.
- **Connection pool exhausted / deadlock / lock timeout**.
- **Migration on a large table** - locks/downtime; **failed migration rollback**.
- **NULL vs empty vs missing column**.
- **Transaction isolation** - dirty/phantom reads.
- **Soft-delete vs hard-delete** - deleted rows leaking into queries.
- **Auto-increment gaps / ID reuse**.

## Caching and CDN
- **Stale cache after update** - invalidation.
- **Cache stampede** - many misses at once hammer the origin.
- **Wrong cache key** - user A sees user B's cached page (**serious leak**).
- **CDN serving an old asset / cache-busting failure**.
- **ETag / 304 handling / partial cache**.

## Concurrency and scale
- **Thundering herd / hot key / hot partition**.
- **Queue backed up / message processed twice / poison message**.
- **Cron overlaps** - previous run still going when the next starts.
- **Distributed lock expires mid-operation**.
- **Eventual consistency** - read-after-write returns the old value.

## Accessibility (often a legal requirement)
- **Keyboard-only navigation / focus traps / focus order**.
- **Screen reader** - alt text, ARIA labels, form errors announced.
- **Color contrast / color-only meaning** (red/green colorblind).
- **Reduced motion / text resize 200% / zoom**.
- **Touch target size / time limits** (warn before auto-logout).

## Data import and export
- **Malformed CSV / wrong encoding** (UTF-8 BOM, Latin-1) / **wrong delimiter**.
- **Huge file** - stream, do not load it all into memory.
- **Excel mangling** - leading zeros dropped, dates/sci-notation auto-convert.
- **CSV formula injection** (`=cmd|...`) - sanitize on export.
- **Quotes/commas/newlines inside fields**.
- **Partial import failure** - row 500 of 1000 fails: rollback or resume?
- **Duplicate rows on re-import / missing required columns**.

## IDs and references
- **ID collision / reused ID after delete**.
- **Guessable sequential IDs** - enumeration (use opaque UUIDs).
- **ID in the wrong format / another entity's ID**.
- **Null foreign reference / dangling pointer**.
- **Case sensitivity in IDs/slugs / URL-encoding of IDs**.

## Mobile-specific
- **App backgrounded mid-action / killed by the OS / low-power mode**.
- **Permission denied** (camera/photos/location/notifications).
- **Offline to online sync / airplane mode**.
- **Deep link / universal link to an uninstalled app**.
- **Push while the app is open vs closed**.
- **Rotation mid-flow / interruption** (call/alarm).
- **Different OS versions / notch and safe-area / slow storage**.

## Next.js App Router, RSC, and SSR
- **Auth only in middleware** - bypassable (CVE-2025-29927); also test the data layer rejects.
- **Auth in a layout** - layouts do not re-render on navigation; the check is skipped on route change.
- **Whole object passed to a Client Component** - assert sensitive fields are not serialized into the payload.
- **Server Action called directly** - with missing/extra/wrong-typed args and as another user (it must re-validate and re-authorize).
- **`searchParams` / dynamic `[param]`** - tampered values (`?isAdmin=true`, another team's slug) must not grant access.
- **`route.ts` GET/POST** - CSRF and auth handled manually; test unauthenticated and cross-origin.
- **Hydration mismatch** - server HTML differs from client (dates, random, `window`-only code).
- **Server vs client component boundary** - `window`/`localStorage` used in a Server Component; `server-only` import leaking.
- **Streaming/Suspense** - error and loading boundaries, partial failure of a streamed segment.
- **`NEXT_PUBLIC_` leak** - a secret accidentally exposed to the browser bundle.
- **Caching** - `revalidate`/`fetch` cache serving stale or another user's data.

## Security abuse / negative testing
- **Replay an old request / tamper with hidden fields or JWT claims**.
- **Parameter pollution** (`?role=user&role=admin`).
- **Negative quantity** (`qty: -5` to credit yourself).
- **Race to redeem a one-time coupon twice**.
- **Mass-assign a privileged field / IDOR via the API**.
- **Bypass client validation by hitting the API directly**.
- **Upload a malicious file / oversized payload (DoS)**.
- **Time-of-check vs time-of-use (TOCTOU)** - state changes between validation and use.

## Analytics and logging
- **Event fires twice / not at all / lost while offline**.
- **PII accidentally logged**.
- **Log injection** - newlines in input forge fake log entries.
- **Clock skew** makes events appear out of order.
