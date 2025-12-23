# Sanitized artifact (007)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
  run-all.ps1
  ──────────────────────────────────────────────────────────────────────────
  • Runs the Step‑5 validation (check-step5.ps1).
  • Aborts on failure.
  • Runs sync‑secrets.ps1 (if present).
  • Prints a friendly “🏁  All tasks finished” banner.

  Usage:
      .\scripts\run-all.ps1                # uses default container name
      .\scripts\run-all.ps1 -DbContainer razzberry-postgres
#>

param(
    [string]$DbContainer = 'razzberry-postgres'
)

# helper for obvious output
function Banner([string]$txt) {
    Write-Host "`n=== $txt ===`n"
}

$repoRoot  = Split-Path $PSScriptRoot -Parent
$checker   = Join-Path $repoRoot 'check-step5.ps1'
$syncer    = Join-Path $PSScriptRoot 'sync-secrets.ps1'

Banner "Razzberry Automation – Full Pass"

# ── 1. Ensure checker exists ────────────────────────────────────────────
if (-not (Test-Path $checker)) {
    Write-Error "check-step5.ps1 not found at $checker – aborting."
    exit 1
}

# ── 2. Run Step‑5 validation ────────────────────────────────────────────
& $checker -DbContainerName $DbContainer
if ($LASTEXITCODE) {
    Write-Error 'Step 5 checker failed – aborting.'
    exit 1
}

# ── 3. Sync secrets (optional) ──────────────────────────────────────────
if (Test-Path $syncer) {
    Banner "Syncing secrets"
    & $syncer
    if ($LASTEXITCODE) {
        Write-Error 'sync‑secrets.ps1 reported an error – aborting.'
        exit 1
    }
} else {
    Write-Warning "sync-secrets.ps1 not found – skipping secret sync"
}

Banner "🏁  All tasks finished. You may now redeploy."

