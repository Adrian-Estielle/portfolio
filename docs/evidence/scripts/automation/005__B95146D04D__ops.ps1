# Sanitized artifact (005)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
Param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$Service = 'razzberry'
$Project = 'razzberry'
$AppUrl  = 'https://<REDACTED_HOST>'
$LogRoot = Join-Path -LiteralPath (Get-Location) -ChildPath '_ops'
$LogDir  = Join-Path $LogRoot 'logs'
$OutDir  = Join-Path $LogRoot 'out'
New-Item -ItemType Directory -Force -Path $LogDir,$OutDir | Out-Null

function Write-Log { param([string]$m) $ts = (Get-Date).ToString('u'); "$ts $m" | Tee-Object -FilePath (Join-Path $LogDir 'ops.log') -Append }
Write-Log '== ops start =='

if (-not $env:RAILWAY_TOKEN) { Write-Error 'RAILWAY_TOKEN env var required'; exit 1 }

# Corepack / pnpm
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) { corepack enable | Out-Null }
corepack prepare pnpm@10.14.0 --activate | Out-Null

# Ensure railway.toml
$railwayToml = @"
[build]
builder = "DOCKERFILE"
dockerfilePath = "Dockerfile"
"@
Set-Content -NoNewline -LiteralPath railway.toml -Value $railwayToml

# dockerignore
$dockerIgnore = @"node_modules
**/.pnpm-store
**/.turbo
**/.next
**/dist
**/build
**/.cache
**/.DS_Store
**/*.log
Documents
__p0_backups
frontend
apps
packages
smoke_output
audit
docs
scripts/old
*.env*
"@
Set-Content -NoNewline -LiteralPath .dockerignore -Value $dockerIgnore

# railwayignore
$railwayIgnore = @"node_modules
**/.pnpm-store
Documents
__p0_backups
frontend
apps
packages
smoke_output
audit
docs
scripts/old
*.env*
"@
Set-Content -NoNewline -LiteralPath .railwayignore -Value $railwayIgnore


# Git add & commit baseline infra files
$baselineFiles = @('railway.toml','.dockerignore','.railwayignore','Dockerfile','scripts/db_migrate_supabase.sh','package.json') | Where-Object { Test-Path $_ }
if ($baselineFiles) { git add $baselineFiles 2>$null }
if (-not (git diff --cached --quiet)) { git commit -m 'chore: ops automation baseline (infra only)' | Out-Null }

# Railway login/init/deploy
pnpm dlx railway login --token $env:RAILWAY_TOKEN | Out-Null
pnpm dlx railway init --project $Project --service $Service --yes | Out-Null
pnpm dlx railway up --service $Service --detach | Out-Null

Write-Log 'Waiting for /health...'
$deadline = (Get-Date).AddMinutes(15)
$up=$false
Do {
  try { $r = Invoke-WebRequest -Uri "$AppUrl/health" -TimeoutSec 5 -UseBasicParsing; if ($r.StatusCode -eq 200) { $up=$true; break } } catch { $up=$false }
  Start-Sleep -Seconds 5
} while ((Get-Date) -lt $deadline)

if (-not $up) {
  Write-Warning 'Service did not become healthy in time. Fetching logs.'
  pnpm dlx railway logs --service $Service --environment production --detach | Select-Object -Last 400 | Tee-Object -FilePath (Join-Path $OutDir 'logs_tail.txt')
  $summary = "APP_BASE_URL=$AppUrl`nsummary: health=FAIL prisma=FAIL redis=N/A"
  $summary | Tee-Object -FilePath (Join-Path $OutDir ("deploy-$((Get-Date).ToString('yyyyMMdd-HHmmss')).txt"))
  Write-Output $summary
  exit 1
}

# Run migrations inside container
pnpm dlx railway run --service $Service bash -lc './scripts/db_migrate_supabase.sh' | Tee-Object -FilePath (Join-Path $LogDir 'migrate.log')

# Postdeploy health
$postOk=$true
node scripts/postdeploy_health.mjs || ($postOk=$false)
if (-not $postOk) { $prisma='FAIL'; $redis='FAIL' } else { $prisma='OK'; $redis='OK' }
$h = if ($up) { 'OK' } else { 'FAIL' }
$final = "APP_BASE_URL=$AppUrl`nsummary: health=$h prisma=$prisma redis=$redis"
$final | Tee-Object -FilePath (Join-Path $OutDir ("deploy-$((Get-Date).ToString('yyyyMMdd-HHmmss')).txt"))
Write-Output $final

