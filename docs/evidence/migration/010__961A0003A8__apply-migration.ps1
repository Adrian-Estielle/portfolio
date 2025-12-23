# Sanitized artifact (010)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
apply-migration.ps1
-------------------

Runs `prisma migrate deploy` against the production database using
your Prisma schema.  This script assumes you’re in the project root and
that `pnpm` is installed.  It checks for a `DATABASE_URL` in the
environment and exits with a warning if it’s missing.

USAGE:

  pwsh ./scripts/apply-migration.ps1

To set the `DATABASE_URL` for your session, run `set-database-url.ps1` first.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not $env:DATABASE_URL) {
    Write-Host "❌ DATABASE_URL not set. Run set-database-url.ps1 first." -ForegroundColor Red
    return
}

# Build the absolute path to the Prisma schema in the backend
$repoRoot = Get-Location
$schemaPath = Join-Path -Path $repoRoot -ChildPath 'prisma/schema.prisma'

if (-not (Test-Path $schemaPath)) {
    Write-Host "❌ Prisma schema not found at $schemaPath" -ForegroundColor Red
    return
}

Write-Host "🚀 Deploying Prisma migrations..." -ForegroundColor Cyan
pnpm exec prisma migrate deploy --schema $schemaPath
Write-Host "✅ Migration deployed." -ForegroundColor Green
