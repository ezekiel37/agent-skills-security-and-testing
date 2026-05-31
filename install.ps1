<#
.SYNOPSIS
  Install agent-security-skills into a target project.
.EXAMPLE
  .\install.ps1 -Target C:\path\to\your\project
#>
param(
  [Parameter(Mandatory = $true)]
  [string]$Target
)

$ErrorActionPreference = "Stop"
$Src = $PSScriptRoot

if (-not (Test-Path $Target)) {
  Write-Error "Target directory does not exist: $Target"
  exit 1
}

Write-Host "Installing agent-security-skills into: $Target"

# Shared skill content (used by every agent)
New-Item -ItemType Directory -Force "$Target\skills" | Out-Null
Copy-Item -Recurse -Force "$Src\skills\security" "$Target\skills\"
Copy-Item -Recurse -Force "$Src\skills\testing"  "$Target\skills\"

# Claude Code project skills
New-Item -ItemType Directory -Force "$Target\.claude\skills" | Out-Null
Copy-Item -Recurse -Force "$Src\skills\security" "$Target\.claude\skills\"
Copy-Item -Recurse -Force "$Src\skills\testing"  "$Target\.claude\skills\"

# Codex / AGENTS.md
if (Test-Path "$Target\AGENTS.md") {
  Write-Host "  AGENTS.md exists - leaving it; see $Src\AGENTS.md to merge."
} else {
  Copy-Item -Force "$Src\AGENTS.md" "$Target\AGENTS.md"
}

# Cursor
New-Item -ItemType Directory -Force "$Target\.cursor\rules" | Out-Null
Copy-Item -Force "$Src\.cursor\rules\agent-security-skills.mdc" "$Target\.cursor\rules\"

# Antigravity / Gemini
New-Item -ItemType Directory -Force "$Target\.antigravity" | Out-Null
Copy-Item -Force "$Src\.antigravity\rules.md" "$Target\.antigravity\"

Write-Host "Done. Skills installed for Claude Code, Codex, Cursor, and Antigravity."
