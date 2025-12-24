# Sanitized artifact (031)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Exports a snapshot of enabled users with Title + Description (+ Office) after a cleanup pass.

When used
- After running a bulk normalization script to capture an “after” dataset for comparison.

Inputs
- SearchBaseDn: DN where the search begins (default: domain root placeholder).
- OutputCsvPath: where to write the CSV.

Safety notes
- Read-only against AD; writes a local CSV output.

Validation
- Compare with the “before” snapshot to confirm expected changes.
- Spot-check a few users directly in AD to ensure Office/Title/Description align.

What was sanitized
- Internal DC/domain identifiers and output paths removed.
- Original local filename: `Descriptions After.ps1`.
#>

[CmdletBinding()]
param(
  [string]$DomainControllerFqdn,
  [string]$SearchBaseDn = 'DC=example,DC=org',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'ad_descriptions_after.csv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

$users = Get-ADUser -Filter { Enabled -eq $true } -SearchBase $SearchBaseDn -Property Title,Description,Office,SamAccountName,ObjectGUID
$users |
  Select-Object Name,SamAccountName,ObjectGUID,Title,Description,Office |
  Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation

Write-Host "Wrote: $OutputCsvPath"

