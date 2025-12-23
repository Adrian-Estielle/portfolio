# Sanitized artifact (013)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
  Run Jenkins locally (Docker) so you can demo "real Jenkins" to yourself and others.

  Requirements:
    - Docker Desktop installed and running

  Usage:
    pwsh -File .\scripts\jenkins_bootstrap.ps1

  Notes:
    - This uses the official Jenkins LTS image
    - It persists data in a named volume (jenkins_home)
#>

$ErrorActionPreference = "Stop"

$jenkinsVolume = "jenkins_home"
$containerName = "jenkins-lts"
$httpPort = 8080
$agentPort = 50000

# Create volume if missing
$existing = docker volume ls --format "{{.Name}}" | Select-String -SimpleMatch $jenkinsVolume
if (-not $existing) {
  docker volume create $jenkinsVolume | Out-Null
}

# If container exists, start it; else run it
$containerExists = docker ps -a --format "{{.Names}}" | Select-String -SimpleMatch $containerName
if ($containerExists) {
  docker start $containerName | Out-Null
} else {
  docker run -d `
    --name $containerName `
    -p "$httpPort`:8080" `
    -p "$agentPort`:50000" `
    -v "$jenkinsVolume`:/var/jenkins_home" `
    jenkins/jenkins:lts | Out-Null
}

Write-Host ""
Write-Host "Jenkins starting at: http://<REDACTED_HOST>"
Write-Host "To get the initial admin password (first run):"
Write-Host "  docker exec $containerName cat /var/jenkins_home/secrets/initialAdminPassword"
Write-Host ""

