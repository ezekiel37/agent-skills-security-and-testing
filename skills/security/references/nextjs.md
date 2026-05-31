# Security Patterns - Next.js App Router, RSC, TypeScript

Next.js App Router, React Server Components (RSC), and Server Actions move data
handling across the server/client boundary in ways that create new, easy-to-miss
risks. This file covers the patterns the framework expects you to follow.

General TS/React patterns (hashing, zod, cookies, uploads) are in
[js-ts.md](js-ts.md). This file is the App Router specifics.

---

## The one rule that prevents most App Router breaches

**Authorize as close to the data as possible - in a Data Access Layer - not in
middleware, not in a layout, not by hiding UI.**

- **Middleware is not a security boundary.** CVE-2025-29927 let attackers skip
  middleware entirely with a crafted `x-middleware-subrequest` header, bypassing
  auth that lived only there. Use middleware for optimistic redirects only; do
  the real check at the data source.
- **Layouts do not re-render on navigation** (partial rendering), so an auth
  check in a layout is not run on every route change. Check in the page/data
  function instead.
- **Hiding a component is not authorization.** There are multiple entry points
  (RSC payloads, Server Actions); a hidden button is still callable.

## Data Access Layer (DAL)

Centralize session verification and data access in server-only modules. Every
data function re-reads the session and checks authorization before returning.

```ts
// app/lib/dal.ts
import "server-only";
import { cache } from "react";
import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { decrypt } from "@/app/lib/session";

// cache() dedupes the check across one render pass
export const verifySession = cache(async () => {
  const cookie = (await cookies()).get("session")?.value;
  const session = await decrypt(cookie);
  if (!session?.userId) redirect("/login");
  return { userId: session.userId as string };
});

export const getUser = cache(async () => {
  const { userId } = await verifySession();
  // Select only the columns you need - never the whole row
  return db.query.users.findFirst({
    where: eq(users.id, userId),
    columns: { id: true, name: true, email: true },
  });
});
```

`import "server-only"` makes the build fail if a Client Component ever imports
this module, so data-access code and secrets cannot leak into the browser bundle.

## Do not pass whole objects to Client Components

Anything a Server Component passes as a prop to a Client Component is serialized
and shipped to the browser. Pass the minimum fields, not the record.

```tsx
// Insecure: the entire user row (password hash, tokens) is serialized to the client
return <Profile user={userData} />;

// Secure: pass only what the component renders
return <Profile name={userData.name} avatarUrl={userData.avatarUrl} />;
```

A Data Transfer Object (DTO) makes the safe shape explicit and field-level
authorization easy:

```ts
// app/lib/dto.ts
import "server-only";

export async function getProfileDTO(slug: string) {
  const viewer = await getUser();
  const user = await db.query.users.findFirst({ where: eq(users.slug, slug) });
  if (!user) return null;
  return {
    username: user.username,
    // field-level check
    phone: viewer?.isAdmin || viewer?.team === user.team ? user.phone : null,
  };
}
```

As defense in depth, you can enable React's taint APIs in `next.config.ts`
(`experimental.taint`) and call `taintObjectReference` / `taintUniqueValue` on
sensitive data, but the DAL/DTO discipline is the real protection.

## Server Actions are public endpoints

`"use server"` exposes every exported function as a callable POST endpoint. The
TypeScript types are not enforced at runtime, and anyone with the action id can
call it with any arguments. So every action must, in order:

```ts
// app/lib/actions.ts
"use server";
import { z } from "zod";
import { verifySession } from "@/app/lib/dal";

const DeletePost = z.object({ id: z.string().uuid() });

export async function deletePost(formData: FormData) {
  // 1. Validate every argument - types are not runtime guarantees
  const parsed = DeletePost.safeParse({ id: formData.get("id") });
  if (!parsed.success) throw new Error("Invalid input");

  // 2. Re-authenticate and re-authorize inside the action
  const { userId } = await verifySession();
  const post = await db.query.posts.findFirst({ where: eq(posts.id, parsed.data.id) });
  if (!post || post.authorId !== userId) throw new Error("Forbidden");

  // 3. Perform the mutation
  await db.delete(posts).where(eq(posts.id, parsed.data.id));
}
```

Notes:
- Server Actions are POST-only and Next.js checks the `Origin` against the
  `Host`, which blocks most CSRF. Custom Route Handlers (`route.ts`) get no such
  protection - add CSRF defenses yourself.
- Closures over rendered data are encrypted by Next.js before being sent to the
  client; `.bind(...)` arguments are **not** encrypted - never bind secrets.
- Middleware that allows viewing a page also allows its Server Actions; do not
  rely on middleware to gate mutations.

## Route Handlers

Treat `route.ts` like any public API: authenticate, authorize, return correct
status codes.

```ts
// app/api/admin/route.ts
import { verifySession } from "@/app/lib/dal";

export async function GET() {
  const session = await verifySession();
  if (!session) return new Response(null, { status: 401 });
  if (session.role !== "admin") return new Response(null, { status: 403 });
  // ...authorized
}
```

## Dynamic params and searchParams are user input

`/[team]/` segments, dynamic params, and `searchParams` are attacker-controlled.
Re-verify access every time; never trust them for authorization.

```tsx
// Insecure: trusting the URL
export default async function Page({ searchParams }: PageProps) {
  if (searchParams.isAdmin === "true") return <AdminPanel />; // never do this
}

// Secure: derive privileges from the verified session, not the URL
export default async function Page({ params }: PageProps) {
  const { userId } = await verifySession();
  const team = await getTeamForUser(userId, params.team); // checks membership
  if (!team) redirect("/");
}
```

## Environment variables

Only variables prefixed `NEXT_PUBLIC_` reach the browser - everything else stays
server-side. Never prefix a real secret. Read `process.env` only inside the DAL
or server-only modules.

```ts
// Insecure: shipped to the browser bundle
const key = process.env.NEXT_PUBLIC_STRIPE_SECRET_KEY;

// Secure: server-only variable, read in a server module
const key = process.env.STRIPE_SECRET_KEY;
```

## Keep RSC dependencies patched

React Server Components had critical 2025 CVEs - CVE-2025-55182 (unsafe
deserialization of the RSC/Flight payload leading to RCE, CVSS 10), plus a DoS
and a source-code/secret exposure issue. The fixes validate incoming payloads
strictly. Pin versions, watch the Next.js and React security advisories, and
patch promptly; this class of bug is not something app code can mitigate.

## Production mode and errors

Run production builds in production mode. In production, React sends a generic
error with a hash (correlate it with server logs) instead of the real message
and stack trace, so sensitive data in an error (`"4111... is not a valid phone"`)
is not leaked to the client. Development mode sends full errors and is not
hardened.

## Audit checklist (App Router specific)

- [ ] Auth verified in the DAL / data functions, not only middleware or layouts
- [ ] `import "server-only"` on data-access and secret-reading modules
- [ ] Client Component props carry minimal fields, not whole records/`User`
- [ ] Every Server Action validates arguments AND re-authorizes
- [ ] `route.ts` handlers authenticate, authorize, and add CSRF protection
- [ ] `params` / `searchParams` re-verified, never used for authorization
- [ ] No real secrets behind `NEXT_PUBLIC_`
- [ ] Next.js and React pinned and patched against known CVEs
