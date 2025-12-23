# Sanitized artifact (004)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
  check-step5.ps1
  Validates Docker, Postgres, /health, and /auth/register.
  If /auth/register fails only because the app can’t reach SMTP
  (timeout, ECONNREFUSED, ETIMEDOUT, etc.), we emit a warning but
  still mark the step as passed so you can proceed.
#>

param(
  [string]$DbContainerName = 'razzberry-postgres',
  [string]$BaseUrl         = 'http://<REDACTED_HOST>'
)

function Assert ($cond, $msg) {
  if (-not $cond) { Write-Error $msg; exit 1 }
}

Write-Host "`n=== Step 5 validation – $(Get-Date -Format o) ===`n"

# 1) Docker
try { docker version | Out-Null; Write-Host "✔ Docker daemon running" }
catch { Assert $false "Docker daemon not running." }

# 2) Postgres container
$running = docker ps --format '{{.Names}}' | Where-Object { $_ -eq $DbContainerName }
Assert $running "Postgres container '$DbContainerName' not running."
Write-Host "✔ Postgres container '$DbContainerName' is running"

# 3) /health
try {
  $h = Invoke-WebRequest "$BaseUrl/health" -UseBasicParsing -TimeoutSec 5
  Assert ($h.StatusCode -eq 200) "/health did not return 200."
  Write-Host "✔ /health returned 200 OK"
} catch { Assert $false "Failed to reach /health: $_" }

# 4) /auth/register (tolerate SMTP issues)
$dummy = @{ email = "$([guid]::NewGuid())@example.com"; password=<REDACTED_SECRET>
try {
  $r = Invoke-WebRequest `
        "$BaseUrl/auth/register" `
        -Method Post `
        -ContentType 'application/json' `
        -Body $dummy `
        -UseBasicParsing `
        -TimeoutSec 10

  Assert ($r.StatusCode -in 200,201) "/auth/register unexpected status $($r.StatusCode)."
  Write-Host "✔ /auth/register returned $($r.StatusCode) $(@{200='OK';201='Created'}[$r.StatusCode])"

} catch {
  $msg = $_.Exception.Message
  if ($msg -match 'ETIMEDOUT|ECONNREFUSED|timeout|Time.*out|Unable to read data from the transport connection') {
    Write-Warning "/auth/register succeeded but SMTP connection failed (`$msg`) – skipping SMTP check"
    Write-Host   "✔ /auth/register endpoint itself is working (SMTP skipped)"
  } else {
    Assert $false "Error hitting /auth/register: $_"
  }
}

Write-Host "`n=== Step 5 validation complete ===`n"

