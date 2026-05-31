#!/usr/bin/env bash
# Install agent-security-skills into a target project.
# Usage: ./install.sh /path/to/your/project
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: ./install.sh /path/to/your/project"
  exit 1
fi

if [[ ! -d "$TARGET" ]]; then
  echo "Error: target directory does not exist: $TARGET"
  exit 1
fi

echo "Installing agent-security-skills into: $TARGET"

# Shared skill content (used by every agent)
mkdir -p "$TARGET/skills"
cp -r "$SRC/skills/security" "$TARGET/skills/"
cp -r "$SRC/skills/testing"  "$TARGET/skills/"

# Claude Code project skills
mkdir -p "$TARGET/.claude/skills"
cp -r "$SRC/skills/security" "$TARGET/.claude/skills/"
cp -r "$SRC/skills/testing"  "$TARGET/.claude/skills/"

# Codex / AGENTS.md
if [[ -f "$TARGET/AGENTS.md" ]]; then
  echo "  AGENTS.md exists - leaving it; see $SRC/AGENTS.md to merge."
else
  cp "$SRC/AGENTS.md" "$TARGET/AGENTS.md"
fi

# Cursor
mkdir -p "$TARGET/.cursor/rules"
cp "$SRC/.cursor/rules/agent-security-skills.mdc" "$TARGET/.cursor/rules/"

# Antigravity / Gemini
mkdir -p "$TARGET/.antigravity"
cp "$SRC/.antigravity/rules.md" "$TARGET/.antigravity/"

echo "Done. Skills installed for Claude Code, Codex, Cursor, and Antigravity."
