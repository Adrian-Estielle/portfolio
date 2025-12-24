# Sanitized artifact (009)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
#
# Script: create-location-migration.ps1
# Purpose : Create and apply a Prisma migration for the new `location` table.
#   When run in a local development environment this script will generate a
#   migration folder under `backend/prisma/migrations` named with the
#   supplied `-Name` parameter and apply it against the database defined
#   by `$Env:DATABASE_URL`.  The script is idempotent: if a migration folder
#   for the given name already exists it will exit without doing anything.
#
# Usage   :
#   # Ensure $Env:DATABASE_URL is set to a *write‑able* Postgres connection.
#   # Then run from the repo root:
#   pwsh ./scripts/create-location-migration.ps1 -Name add_location
#
#   You can omit `-Name` to use the default `add_location`.
#
param(
    [string]$Name = "add_location"
)

# Resolve paths relative to this script's location.  We assume this script
# resides in the `scripts` folder at the root of the repository.
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RepoRoot = Resolve-Path (Join-Path $ScriptDir '..')
$SchemaPath = Join-Path $RepoRoot 'backend/prisma/schema.prisma'
$MigrationsDir = Join-Path $RepoRoot 'backend/prisma/migrations'

# Check for the required DATABASE_URL environment variable.  Prisma uses
# this variable to know where to apply migrations.  Without it, the
# migration cannot be created or applied.
if (-not $Env:DATABASE_URL) {
    Write-Warning "The environment variable DATABASE_URL is not set. Cannot run Prisma migrations."
    Write-Warning "Set DATABASE_URL to your PostgreSQL connection string (e.g. the Railway external URL) and re‑run."
    exit 1
}

# Ensure the schema file exists.  Exit early if not found so that the
# script does not attempt to run Prisma in a misconfigured state.
if (-not (Test-Path $SchemaPath)) {
    Write-Error "Prisma schema not found at $SchemaPath. Are you running from the repository root?"
    exit 1
}

# Check if a migration with this name has already been generated.  Prisma
# names migrations with a timestamp prefix followed by the provided name
# (e.g. `20250624120000_add_location`).  We scan for any folder that
# ends with _$Name and, if found, skip migration creation.
$ExistingMigration = Get-ChildItem -Path $MigrationsDir -Directory |
    Where-Object { $_.Name -like "*_${Name}" }

if ($ExistingMigration) {
    Write-Host "Migration '$Name' already exists at '$($ExistingMigration.FullName)'. No action taken."
    exit 0
}

# Build the Prisma migrate command.  We explicitly reference the schema path
# because the monorepo may contain multiple schemas.
$MigrateCmd = "pnpm prisma migrate dev --name $Name --schema $SchemaPath"
Write-Host "Running: $MigrateCmd"

try {
    # Invoke the command in a subshell (bash) so that `pnpm` resolution
    # and any environment scripts work as expected.  Use `--color never`
    # to suppress ANSI codes when not running interactively.
    $process = Start-Process -FilePath "bash" -ArgumentList "-lc", $MigrateCmd -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        throw "Prisma migrate command failed with exit code $($process.ExitCode)."
    }
    Write-Host "Migration '$Name' created and applied successfully."
} catch {
    Write-Error $_
    exit 1
}
