# Sanitized artifact (030)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Exports a snapshot of enabled users with Title + Description (baseline before a cleanup pass).

When used
- Before running a bulk normalization script to establish a “before” dataset.

Inputs
- SearchBaseDn: DN where the search begins (default: domain root placeholder).
- OutputCsvPath: where to write the CSV.

Safety notes
- Read-only against AD; writes a local CSV output.

Validation
- Confirm the CSV has expected columns and a reasonable row count.
- Spot-check a few users for accurate Title/Description values.

What was sanitized
- Internal DC/domain identifiers and output paths removed.
- Original local filename: `Descriptions.ps1`.
#>

[CmdletBinding()]
param(
  [string]$DomainControllerFqdn,
  [string]$SearchBaseDn = 'DC=example,DC=org',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'ad_descriptions_before.csv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

$users = Get-ADUser -Filter { Enabled -eq $true } -SearchBase $SearchBaseDn -Property Title,Description,SamAccountName,ObjectGUID
$users |
  Select-Object Name,SamAccountName,ObjectGUID,Title,Description |
  Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation

Write-Host "Wrote: $OutputCsvPath"

