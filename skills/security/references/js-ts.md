# Security Patterns - JavaScript / TypeScript

Insecure-to-secure snippets for modern TypeScript, Node, and React. For Next.js
App Router, Server Actions, and React Server Components, see
[nextjs.md](nextjs.md).

Conventions: examples are TypeScript, use `async/await`, and validate input with
[zod](https://zod.dev). Marked `// Insecure` (do not ship) and `// Secure`.

---

## Password hashing

```ts
// Insecure: fast, unsalted hash is brute-forceable
import { createHash } from "node:crypto";
const hash = createHash("sha256").update(password).digest("hex");

// Secure: argon2id (preferred) or bcrypt
import argon2 from "argon2";
const hash = await argon2.hash(password); // store this
const ok = await argon2.verify(hash, password); // on login
```

## Input validation with a shared schema

Define the schema once and reuse it on both client and server. The server check
is the one that counts.

```ts
import { z } from "zod";

export const SignupSchema = z.object({
  username: z.string().min(3).max(20).regex(/^[a-z0-9_]+$/i),
  email: z.string().email().transform((s) => s.trim().toLowerCase()),
  password: z
    .string()
    .min(9)
    .regex(/[A-Z]/, "needs an uppercase letter")
    .regex(/[a-z]/, "needs a lowercase letter")
    .regex(/[0-9]/, "needs a number")
    .regex(/[^A-Za-z0-9]/, "needs a symbol"),
});

export type SignupInput = z.infer<typeof SignupSchema>;
```

```ts
// Secure: the server re-validates even when the client already did
const parsed = SignupSchema.safeParse(await req.json());
if (!parsed.success) {
  return Response.json({ errors: parsed.error.flatten() }, { status: 422 });
}
```

## SQL injection

```ts
// Insecure: string interpolation
db.query(`SELECT * FROM users WHERE email = '${email}'`);

// Secure: parameterized query
db.query("SELECT id, email FROM users WHERE email = $1", [email]);

// Secure: ORM safe API (Prisma). Never use $queryRawUnsafe with user input.
await prisma.user.findUnique({ where: { email } });
```

## Authorization and IDOR

Authentication tells you who the caller is. Authorization checks that this caller
may touch this specific record. Check ownership on every read and write.

```ts
// Insecure: returns any order by id
async function getOrder(id: string, user: User) {
  return db.order.findById(id); // user A can read user B's order
}

// Secure: enforce ownership; 404 avoids confirming the record exists
async function getOrder(id: string, user: User) {
  const order = await db.order.findById(id);
  if (!order || order.userId !== user.id) return null;
  return order;
}
```

## Mass assignment

```ts
// Insecure: binds the whole body, so { isAdmin: true } slips in
await db.user.update(user.id, body);

// Secure: validate and pick only the fields the user may set
const data = ProfileSchema.parse(body); // { displayName, bio }
await db.user.update(user.id, data);
```

## XSS

```tsx
// Insecure
<div dangerouslySetInnerHTML={{ __html: userContent }} />;

// Secure: render as text; React escapes it
<div>{userContent}</div>;

// Secure: if you must render HTML, sanitize first
import DOMPurify from "dompurify";
<div dangerouslySetInnerHTML={{ __html: DOMPurify.sanitize(userContent) }} />;
```

## SSRF

```ts
// Secure: allowlist host and scheme; block internal ranges
async function fetchExternal(rawUrl: string) {
  const url = new URL(rawUrl);
  const allowed = new Set(["api.partner.com"]);
  if (url.protocol !== "https:" || !allowed.has(url.hostname)) {
    throw new Error("URL not allowed");
  }
  return fetch(url, { signal: AbortSignal.timeout(5000) });
}
```

## Secure cookies

```ts
// Express-style options; set the same flags in any framework
res.cookie("session", token, {
  httpOnly: true, // JS cannot read it, so XSS cannot steal it
  secure: true, // HTTPS only
  sameSite: "lax", // CSRF mitigation
  maxAge: 1000 * 60 * 60 * 24 * 7,
  path: "/",
});
// Do not store auth tokens in localStorage.
```

## JWT verification

```ts
// Secure: pin the algorithm to reject "none" and algorithm-confusion attacks
jwt.verify(token, PUBLIC_KEY, { algorithms: ["RS256"], maxAge: "15m" });
```

## Rate limiting

```ts
import rateLimit from "express-rate-limit";
const authLimiter = rateLimit({ windowMs: 15 * 60_000, max: 10 });
app.post("/login", authLimiter, loginHandler);
app.post("/password-reset", authLimiter, resetHandler);
```

## CORS

```ts
// Insecure: wildcard with credentials
app.use(cors({ origin: "*", credentials: true }));

// Secure: allowlist specific origins
app.use(cors({ origin: ["https://app.example.com"], credentials: true }));
```

## Correct status codes

```ts
if (!user) return Response.json({ error: "Not authenticated" }, { status: 401 });
if (!allowed) return Response.json({ error: "Forbidden" }, { status: 403 });
if (!found) return Response.json({ error: "Not found" }, { status: 404 });
if (invalid) return Response.json({ error: "Validation failed" }, { status: 422 });
if (conflict) return Response.json({ error: "Already exists" }, { status: 409 });
// Never return status 200 with an error body.
```

## Password field with a visibility toggle (React)

```tsx
import { useState } from "react";

export function PasswordField({ name, value, onChange }: PasswordFieldProps) {
  const [visible, setVisible] = useState(false);
  return (
    <div className="password-field">
      <input
        type={visible ? "text" : "password"}
        name={name}
        value={value}
        onChange={onChange}
        autoComplete="new-password"
      />
      <button
        type="button"
        aria-label={visible ? "Hide password" : "Show password"}
        aria-pressed={visible}
        onClick={() => setVisible((v) => !v)}
      >
        {visible ? "Hide" : "Show"}
      </button>
    </div>
  );
}
```

Pair it with a confirm-password field, check the two match, then re-validate the
password policy on the server.

## File upload validation

```ts
import { fileTypeFromBuffer } from "file-type";

const MAX_BYTES = 5 * 1024 * 1024;
const ALLOWED = new Set(["image/png", "image/jpeg", "image/webp"]);

async function validateUpload(buffer: Buffer) {
  if (buffer.length > MAX_BYTES) throw new Error("File too large");
  const type = await fileTypeFromBuffer(buffer); // checks magic bytes, not the name
  if (!type || !ALLOWED.has(type.mime)) throw new Error("Unsupported file type");
  return type.mime;
}
// Store outside the web root; serve with X-Content-Type-Options: nosniff.
```
