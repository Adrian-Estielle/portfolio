# Sanitized artifact (012)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
  Local build helper (Windows PowerShell or PowerShell 7).
  This is intentionally simple + readable.

  Usage:
    pwsh -File .\scripts\build.ps1
#>

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
Push-Location $repoRoot

try {
  $config = "Release"
  $artifactDir = Join-Path $repoRoot "artifacts"

  if (Test-Path $artifactDir) { Remove-Item $artifactDir -Recurse -Force }
  New-Item -ItemType Directory -Path $artifactDir | Out-Null

  dotnet restore .\HelloBuild.sln
  dotnet build .\HelloBuild.sln -c $config --no-restore
  dotnet test .\HelloBuild.sln -c $config --no-build

  $publishDir = Join-Path $artifactDir "HelloBuild"
  dotnet publish .\src\HelloBuild\HelloBuild.csproj -c $config -o $publishDir

  $commit = (git rev-parse HEAD) 2>$null
  "git_commit=$commit" | Out-File (Join-Path $artifactDir "build_metadata.txt") -Encoding utf8

  Write-Host "✅ Build complete. Artifacts at: $artifactDir"
}
finally {
  Pop-Location
}

