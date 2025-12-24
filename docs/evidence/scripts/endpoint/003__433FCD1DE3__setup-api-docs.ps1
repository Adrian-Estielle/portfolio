# Sanitized artifact (003)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
 Automates API cheatsheet tooling for the flattened backend.
 • Installs dev deps (express-list-endpoints, ts-node) in the active backend package
 • Creates scripts/generate-api-cheatsheet.ts if absent
 • Adds "doc:routes" to package.json so `pnpm run doc:routes` works from repo root
 • Remains backward-compatible if legacy backend/ folder still exists
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Stop-Here([string]$msg) {
    Write-Host "`nFATAL: $msg" -ForegroundColor Red
    return
}

# ───── Locate repo root ─────
$start = if ($PSScriptRoot) { $PSScriptRoot } else { $PWD.Path }
while ($start -and -not (Test-Path (Join-Path $start '.git'))) {
    $parent = Split-Path $start -Parent
    if ($parent -eq $start) { $start = $null; break }
    $start = $parent
}
if (-not $start) { Stop-Here 'Not inside a git repository (no .git found).'; return }

$root = (Resolve-Path $start).Path
Write-Host "📂 Repo root → $root" -ForegroundColor Cyan

# ───── Determine backend package path ─────
$legacyBackend = Join-Path $root 'backend/package.json'
if (Test-Path $legacyBackend) {
    $backendDir = Split-Path $legacyBackend -Parent
    $pnpmFilter = './backend'
    Write-Host "↪ Legacy backend/ layout detected; operating inside $backendDir" -ForegroundColor Yellow
} else {
    $backendDir = $root
    $pnpmFilter = '.'
    Write-Host "✅ Flattened backend detected at repo root" -ForegroundColor Green
}

$backendPkgPath = Join-Path $backendDir 'package.json'
if (-not (Test-Path $backendPkgPath)) { Stop-Here "package.json not found at $backendDir"; return }

# ───── Ensure dev dependencies ─────
function Ensure-DevDep([string]$pkg) {
    $pkgJson = Get-Content $backendPkgPath -Raw | ConvertFrom-Json
    $hasDep = $false
    if ($pkgJson.devDependencies -and $pkgJson.devDependencies.$pkg) { $hasDep = $true }
    elseif ($pkgJson.dependencies -and $pkgJson.dependencies.$pkg) { $hasDep = $true }

    if ($hasDep) {
        Write-Host "↪ $pkg already present."
        return
    }

    Write-Host "➕ Adding $pkg (dev dependency)."
    if (Get-Command pnpm -ErrorAction SilentlyContinue) {
        if ($pnpmFilter -eq '.') {
            pnpm add -D $pkg | Out-Null;
        } else {
            pnpm --filter $pnpmFilter add -D $pkg | Out-Null;
        }
    } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
        Push-Location $backendDir
        npm install --save-dev $pkg | Out-Null
        Pop-Location
    } else {
        Stop-Here 'Neither pnpm nor npm available to install dependencies.'
    }
}

Ensure-DevDep 'express-list-endpoints'
Ensure-DevDep 'ts-node'

# ───── Generator script ─────
if ($backendDir -eq $root) {
    $gen = Join-Path $root 'scripts/generate-api-cheatsheet.ts'
    $importPath = './index.js'
} else {
    $gen = Join-Path $backendDir 'scripts/generate-api-cheatsheet.ts'
    $importPath = '../index.js'
}

if (-not (Test-Path $gen)) {
    New-Item -ItemType Directory -Force -Path (Split-Path $gen) | Out-Null
@"
import fs from 'fs';
import listEndpoints from 'express-list-endpoints';
import app from '$importPath';

const eps = listEndpoints(app);
let out = `
===================== RAZZBERRY API CHEAT-SHEET =====================

Base URL  : https://<REDACTED_HOST>
Auth      : Bearer <REDACTED_TOKEN> (Authorization header)

--------------------------------------------------------------------
`;
for (const e of eps) {
  for (const method of e.methods) {
    out += `${method.padEnd(6)} ${e.path}\n`;
  }
}
out += '\n--------------------------------------------------------------------\n';
fs.writeFileSync('API_CHEATSHEET.txt', out.trim() + '\n', 'utf8');
console.log('✅  API_CHEATSHEET.txt generated.');
"@ | Set-Content $gen -Encoding UTF8
    Write-Host "📝 Created $gen"
} else {
    Write-Host "↪ generator script already exists at $gen"
}

# ───── Add root script entry ─────
$rootPkgPath = Join-Path $root 'package.json'
$rootPkg     = Get-Content $rootPkgPath -Raw | ConvertFrom-Json
if (-not $rootPkg.scripts) { $rootPkg | Add-Member -NotePropertyName scripts -NotePropertyValue @{} }
$scriptValue = if ($backendDir -eq $root) {
    'pnpm exec ts-node scripts/generate-api-cheatsheet.ts'
} else {
    'pnpm --filter backend exec ts-node scripts/generate-api-cheatsheet.ts'
}
if ($rootPkg.scripts.PSObject.Properties.Name -notcontains 'doc:routes' -or $rootPkg.scripts.'doc:routes' -ne $scriptValue) {
    $rootPkg.scripts.'doc:routes' = $scriptValue
    $rootPkg | ConvertTo-Json -Depth 10 | Set-Content $rootPkgPath -Encoding UTF8
    Write-Host '✍️  Updated "doc:routes" in package.json.'
} else {
    Write-Host '↪ "doc:routes" already up-to-date.'
}

Write-Host "`n🎉  Setup complete.  Run  pnpm run doc:routes  to refresh API_CHEATSHEET.txt." -ForegroundColor Green

