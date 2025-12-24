# Sanitized artifact (024)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Exports Name / Title / Description for users under a target OU (optionally including sub-OUs).

When used
- Building a role/attribute baseline, or validating bulk Description normalization.

Inputs
- DomainControllerFqdn: DC hostname/FQDN (optional).
- TargetOuDn: distinguishedName of the OU to query.
- SearchScope: OneLevel or Subtree.
- OutputCsvPath: where to write the CSV.

Safety notes
- Read-only against AD; writes a local CSV output.

Validation
- Open the CSV and spot-check a few users directly in AD.
- Confirm SearchScope is intentional (Subtree can be large).

What was sanitized
- Internal DC hostnames, OU DNs, and output paths removed.
- Original local filename: `Pull title description name.ps1`.
#>

[CmdletBinding()]
param(
  [string]$DomainControllerFqdn,
  [Parameter(Mandatory = $true)]
  [string]$TargetOuDn = 'OU=<DEPARTMENT>,OU=Users,DC=example,DC=org',
  [ValidateSet('OneLevel','Subtree')]
  [string]$SearchScope = 'Subtree',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'ou_name_title_description.csv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

$users = Get-ADUser -Filter * -SearchBase $TargetOuDn -SearchScope $SearchScope -Property Title,Description
$users |
  Select-Object Name,Title,Description |
  Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation

Write-Host "Wrote: $OutputCsvPath"

