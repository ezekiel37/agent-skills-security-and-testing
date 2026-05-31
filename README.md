# agent-security-skills

Security and testing skills for AI coding agents - **Claude Code, Codex, Cursor, Antigravity, and any agent that reads Markdown.**

Vibe coders and AI agents ship the happy path. They miss the stuff that actually breaks apps and leaks data: authorization on every endpoint, server-side validation, race conditions, edge cases, and the tests that catch regressions nobody thought about.

These two skills teach your agent to:

- **Write secure code by default** and audit existing code against a real checklist (SANS SWAT / OWASP-aligned), including modern Next.js App Router, React Server Components, and Server Actions.
- **Test beyond the happy path** - edge cases, failure paths, and abuse, with a ~230-item edge-case bank.

> **Philosophy:** Test that users *can* use the app. Equally, test that it *doesn't break* on bad data or unexpected actions, and that data *can't be compromised*. A good test suite tries to break your app and reveals its limits. And tests are code too - review them; they're the last gate to production.

---

## What's inside

```
agent-security-skills/
  skills/
    security/          secure-by-default coding + audit checklist
      SKILL.md
      checklist.md
      references/      deep dives + JS/TS, Python, Next.js code
    testing/           test beyond the happy path
      SKILL.md
      checklist.md
      references/      edge-case bank + JS/TS & Python code
  AGENTS.md            entry point for Codex & AGENTS.md-aware agents
  .cursor/rules/       Cursor wrapper
  .antigravity/        Antigravity / Gemini wrapper
```

The content lives **once** in `skills/`. Every other agent format is a thin pointer to it.

---

## Install

### Claude Code (project skills)

Copy the two skill folders into your project (or `~/.claude/skills` for global):

```bash
# from your project root
mkdir -p .claude/skills
cp -r path/to/agent-security-skills/skills/security .claude/skills/
cp -r path/to/agent-security-skills/skills/testing  .claude/skills/
```

Windows PowerShell:

```powershell
New-Item -ItemType Directory -Force .claude\skills | Out-Null
Copy-Item -Recurse path\to\agent-security-skills\skills\security .claude\skills\
Copy-Item -Recurse path\to\agent-security-skills\skills\testing  .claude\skills\
```

Claude auto-discovers skills by their `SKILL.md` frontmatter and loads them when relevant.

### Codex / AGENTS.md-aware agents

Copy `AGENTS.md` to your project root (or merge its contents into your existing `AGENTS.md`), and copy the `skills/` folder alongside it. The agent reads `AGENTS.md`, which points it at the skill files.

### Cursor

Copy `.cursor/rules/` into your project. Cursor loads the rule files automatically.

### Antigravity / Gemini

Copy `.antigravity/` into your project (or paste `.antigravity/rules.md` into your agent's system/rules configuration).

### One-shot installer

```bash
./install.sh /path/to/your/project          # macOS / Linux
```

```powershell
.\install.ps1 -Target C:\path\to\your\project   # Windows
```

The installer copies `skills/` and the matching wrapper files into the target project.

---

## How to use it

**Passive (recommended):** once installed, the agent reads the skills while it codes and applies the rules automatically - fewer vulnerabilities and missing cases from the start.

**Active audit:** ask the agent to run a pass:

- *"Run the security checklist against this code."* loads `skills/security/checklist.md`
- *"What edge cases am I missing here?"* loads `skills/testing/references/edge-cases.md`

---

## Scope (v1)

- **Principles are language-agnostic** - they apply to any stack.
- **Concrete code examples** target **JavaScript/TypeScript** (Node, React, Next.js App Router/RSC) and **Python**, the most common vibe-coder stacks.
- More stacks and topics (mobile-native, Go, Rust, GraphQL depth) are planned for later versions.

## Contributing

PRs welcome - add edge cases, language packs, or framework-specific notes. Keep the principle language-agnostic in `SKILL.md` and put concrete code in `references/`.

## License

[MIT](LICENSE)
