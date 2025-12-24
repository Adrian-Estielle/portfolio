# Sanitized artifact (015)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# project-contents.ps1
# Reads contents of all relevant source files into one output file.

[CmdletBinding()]
param(
  [string]$Root = (Get-Location).Path,
  [string]$OutputFile = (Join-Path -Path (Get-Location) -ChildPath 'contents.txt')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$Root = (Resolve-Path -LiteralPath $Root).Path
$outDir = Split-Path -Parent $OutputFile
if ($outDir -and -not (Test-Path -LiteralPath $outDir)) {
  New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$includeExts = @("*.js", "*.ts", "*.tsx", "*.jsx", "*.json", "*.toml", "*.yml", "*.yaml", "*.env*", "*.md", "*.ps1", "*.sh", "*.html", "*.css", "*.prisma")
$excludeDirs = @("node_modules", ".git", ".next", ".output", "dist", "build", "logs", "__pycache__")

$files = Get-ChildItem -Path $Root -Recurse -File -Include $includeExts | Where-Object {
  $rel = $_.FullName.Substring($Root.Length + 1)
  $excludeDirs -notcontains ($rel.Split([IO.Path]::DirectorySeparatorChar)[0])
}

@() | Out-File -LiteralPath $OutputFile -Encoding UTF8  # clear file

foreach ($file in $files) {
  $rel = $file.FullName.Substring($Root.Length + 1)
  Add-Content -LiteralPath $OutputFile -Value "`n===== FILE: $rel =====`n" -Encoding UTF8
  Get-Content -LiteralPath $file.FullName -Raw | Add-Content -LiteralPath $OutputFile -Encoding UTF8
}
Write-Host "Full contents dump saved to: $OutputFile"

