# Testing Patterns - JavaScript / TypeScript

Examples use **Vitest** (Jest is nearly identical) and **Playwright** for e2e.
The patterns matter more than the runner.

---

## Structure: Arrange-Act-Assert

```ts
import { describe, it, expect } from "vitest";

describe("calculateTotal", () => {
  it("applies tax to the subtotal", () => {
    const total = calculateTotal({ subtotal: 100_00, taxRate: 0.1 }); // cents
    expect(total).toBe(110_00);
  });
});
```

## Cover the three lenses

```ts
describe("createUser", () => {
  it("creates a user with valid input", async () => {
    const user = await createUser({
      username: "ada",
      email: "a@x.com",
      password: "Str0ng!pass",
    });
    expect(user.id).toBeDefined();
  });

  it("rejects a short username", async () => {
    await expect(
      createUser({ username: "ab", email: "a@x.com", password: "Str0ng!pass" }),
    ).rejects.toThrow(/username/i);
  });

  it("ignores isAdmin sent via mass assignment", async () => {
    const user = await createUser({
      username: "ada",
      email: "a@x.com",
      password: "Str0ng!pass",
      isAdmin: true,
    } as never);
    expect(user.isAdmin).toBe(false);
  });
});
```

## Edge cases with `it.each`

```ts
it.each([
  ["empty", ""],
  ["whitespace only", "   "],
  ["too short", "ab"],
  ["too long", "a".repeat(50)],
  ["multi-byte", "\u{1F600}\u{1F1EF}\u{1F1F5}"],
  ["sql-ish", "'; DROP TABLE users;--"],
])("rejects invalid username: %s", async (_label, username) => {
  await expect(validateUsername(username)).rejects.toThrow();
});
```

## Boundaries

```ts
it.each([
  [8, false], // below min
  [9, true], // exactly min
  [10, true],
])("password length %i valid=%s", (len, valid) => {
  expect(isValidPassword("Aa1!".padEnd(len, "x"))).toBe(valid);
});
```

## Money and float precision

```ts
it("never loses cents to float math", () => {
  // 0.1 + 0.2 === 0.30000000000000004, so work in integer cents
  expect(addMoney(10, 20)).toBe(30);
});
```

## Deterministic time

```ts
import { vi, afterEach } from "vitest";

afterEach(() => vi.useRealTimers());

it("marks tokens expired after 15 minutes", () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-01-01T00:00:00Z"));
  const token = issueToken();

  vi.setSystemTime(new Date("2026-01-01T00:16:00Z"));
  expect(isExpired(token)).toBe(true);
});
```

## Mocking the network (no real calls)

```ts
import { vi } from "vitest";

it("handles a 500 from the payment API", async () => {
  vi.spyOn(globalThis, "fetch").mockResolvedValue(
    new Response("boom", { status: 500 }),
  );
  await expect(charge(order)).rejects.toThrow(/payment failed/i);
});

it("times out a slow dependency", async () => {
  vi.spyOn(globalThis, "fetch").mockImplementation(
    () => new Promise(() => {}), // never resolves
  );
  await expect(charge(order, { timeoutMs: 50 })).rejects.toThrow(/timeout/i);
});
```

## API contract: assert status AND shape

```ts
import request from "supertest";

it("returns 422 with field errors on bad signup", async () => {
  const res = await request(app).post("/api/signup").send({ username: "ab" });
  expect(res.status).toBe(422);
  expect(res.body).toMatchObject({
    error: expect.any(String),
    fields: expect.any(Object),
  });
});

it("uses 401 vs 403 correctly", async () => {
  const anon = await request(app).get("/api/admin");
  expect(anon.status).toBe(401); // no token

  const user = await request(app).get("/api/admin").set("Authorization", userToken);
  expect(user.status).toBe(403); // authenticated, not admin
});
```

## Authorization / IDOR

```ts
it("forbids reading another user's order", async () => {
  const res = await request(app)
    .get(`/api/orders/${userBOrderId}`)
    .set("Authorization", userAToken);
  expect(res.status).toBe(404); // ownership enforced
});
```

## Idempotency / double-submit

```ts
it("charges once even if the request is sent twice", async () => {
  const key = "idem-123";
  await charge(order, { idempotencyKey: key });
  await charge(order, { idempotencyKey: key });
  expect(await countCharges(order.id)).toBe(1);
});
```

## Regression test (write it before fixing)

```ts
// Bug #482: negative quantity credited the user. This test failed before the fix.
it("rejects negative quantity (regression #482)", async () => {
  const res = await request(app).post("/api/cart").send({ productId: "p1", qty: -5 });
  expect(res.status).toBe(422);
});
```

## React: loading / error / empty states

```tsx
it("shows an empty state when there are no items", () => {
  render(<List items={[]} />);
  expect(screen.getByText(/nothing here yet/i)).toBeInTheDocument();
});
```

## End-to-end critical path (Playwright)

```ts
import { test, expect } from "@playwright/test";

test("user can sign up and reach the dashboard", async ({ page }) => {
  await page.goto("/signup");
  await page.getByLabel("Username").fill("ada");
  await page.getByLabel("Email").fill("ada@example.com");
  await page.getByLabel("Password", { exact: true }).fill("Str0ng!pass");
  await page.getByLabel("Confirm password").fill("Str0ng!pass");
  await page.getByRole("button", { name: "Create account" }).click();
  await expect(page).toHaveURL(/dashboard/);
});
```
