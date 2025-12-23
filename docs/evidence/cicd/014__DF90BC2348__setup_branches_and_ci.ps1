# Sanitized artifact (014)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
 .SYNOPSIS
   Initializes branch structure and CI pipeline for the repository.
 .DESCRIPTION
   - Creates "frontend-dev" and "backend-dev" branches off current main.
   - Creates a "snapshot-<date>" branch tagging the current main state.
   - Adds a GitHub Actions workflow for CI checks (build & syntax validation).
   - Optionally enables branch protection on main (requires GitHub CLI).
 .NOTES
   Run this script from the repository root directory in a PowerShell terminal.
   Ensure you have commit/push rights and GH CLI is authenticated for branch protection step.
#>

# Stop on any error
$ErrorActionPreference = 'Stop'

Write-Host "🏷  Creating snapshot branch of current main..." -ForegroundColor Cyan
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$snapshotBranch = "snapshot-$timestamp"
git branch $snapshotBranch
git push origin $snapshotBranch
Write-Host "✅ Snapshot branch '$snapshotBranch' created and pushed."

Write-Host "🌿 Creating separate dev branches for frontend and backend..." -ForegroundColor Cyan
# Create frontend-dev branch
git branch frontend-dev
git push origin frontend-dev
# Create backend-dev branch
git branch backend-dev
git push origin backend-dev
Write-Host "✅ Created 'frontend-dev' and 'backend-dev' branches from main (both pushed to origin)."

Write-Host "🔧 Adding CI workflow file for build checks..." -ForegroundColor Cyan
# Ensure .github/workflows exists
New-Item -ItemType Directory -Force -Path ".github\workflows" | Out-Null
$workflowYml = @"
name: CI Checks
on:
  push:
    branches: [ main, frontend-dev, backend-dev ]
  pull_request:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: 🗄️ Checkout code
        uses: actions/checkout@v3
      - name: 📦 Setup pnpm
        uses: pnpm/action-setup@v4
        with:
          run_install: false  # We'll run pnpm install explicitly
      - name: 📥 Install dependencies
        run: pnpm install
      - name: 🔨 Build frontend (compile & bundle)
        run: pnpm --filter razzberry-frontend run build
      - name: 🏗️ Validate Prisma schema
        run: pnpm exec prisma validate --schema=backend/prisma/schema.prisma
      - name: ⚡ Quick syntax check (backend)
        run: node -c backend/index.js
"@
$ciFile = ".github/workflows/ci-checks.yml"
$workflowYml | Set-Content -Path $ciFile -Encoding UTF8
git add $ciFile
git commit -m "Add CI workflow for build and basic validations"
git push origin main
Write-Host "✅ CI workflow file added and pushed to main. (The pipeline will run on future pushes/PRs.)"

# Optional: Protect main branch (requires GitHub CLI with proper permissions)
if (Get-Command gh -ErrorAction SilentlyContinue) {
    Write-Host "🔒 Configuring branch protection on 'main' (no direct pushes, require PR)..." -ForegroundColor Cyan
    gh api -X PUT repos/$((git config --get remote.origin.url) -replace 'https://github.com/|<REDACTED_EMAIL>:|.git','')/branches/main/protection `
      -F enforce_admins=true `
      -F allow_force_pushes=false `
      -F allow_deletions=false `
      -F required_pull_request_reviews.dismiss_stale_reviews=true `
      -F required_pull_request_reviews.required_approving_review_count=0 `
      -F required_pull_request_reviews.require_code_owner_reviews=false `
      -F required_status_checks.strict=true `
      -F required_status_checks.contexts='[]'  > $null
    Write-Host "✅ 'main' branch protection rules applied (pull requests required for merges)." -ForegroundColor Green
} else {
    Write-Host "⚠️ GitHub CLI not found. Please enable 'main' branch protection manually in repository settings." -ForegroundColor Yellow
}

