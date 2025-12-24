# Sanitized artifact (029)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Normalizes user `Description` values within a target OU **including sub-OUs** (Subtree) and exports a before/after CSV report.
- Preserves LOA-style markers (leave-of-absence) by default.

When used
- OU-scoped cleanup when a provisioning project spans multiple nested OUs.

Inputs
- TargetOuDn: DN of the OU to scan.
- Apply: actually writes changes; otherwise produces a dry-run report.
- OutputCsvPath: where to write the report CSV.

Safety notes
- Defaults to dry-run (no AD writes) unless `-Apply` (or `-WhatIf`).
- Supports `-WhatIf` / `-Confirm`.
- Subtree scans can be large; test in a small OU first.

Validation
- Confirm the number of affected users is expected for the OU subtree.
- Confirm LOA accounts were preserved as intended.

What was sanitized
- Internal DC/OU identifiers and output paths removed.
- Original local filename: `update descriptions V3 Only OU and sub OUs.ps1`.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [string]$DomainControllerFqdn,
  [Parameter(Mandatory = $true)]
  [string]$TargetOuDn = 'OU=<TARGET_OU>,DC=example,DC=org',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'description_changes_ou_subtree.csv'),
  [switch]$Apply,
  [switch]$PreserveLoa = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

function Get-NormalizedDescription([AllowEmptyString()][string]$Description) {
  if (-not $Description) { return $null }
  if ($PreserveLoa -and ($Description -match 'loa')) { return $Description }

  if ($Description -match 'consultant') { return 'CONSULTANT' }
  if ($Description -match 'contractor') { return 'CONTRACTOR' }
  if ($Description -match 'temp') { return 'TEMP' }
  if ($Description -match 'vendor') { return 'VENDOR' }
  if ($Description -match 'test|testing') { return 'TEST ACCOUNT' }
  return 'FULL-TIME'
}

if (-not $Apply -and -not $WhatIfPreference) {
  Write-Warning "Dry run: no AD changes will be applied. Re-run with -Apply (or use -WhatIf to preview actions)."
}

$users = Get-ADUser -Filter * -SearchBase $TargetOuDn -SearchScope Subtree -Property Description,Title,SamAccountName
$total = $users.Count
$count = 0

$report = foreach ($u in $users) {
  $count++
  Write-Progress -Activity 'Normalizing user descriptions (OU subtree)' -Status "$count/$total" -PercentComplete (($count / [Math]::Max(1,$total)) * 100)

  $before = $u.Description
  $after = Get-NormalizedDescription -Description $before
  $changed = ($after -ne $null) -and ($after -ne $before)

  if ($Apply -or $WhatIfPreference) {
    if ($changed -and $PSCmdlet.ShouldProcess($u.SamAccountName, "Set Description='$after'")) {
      Set-ADUser -Identity $u -Description $after
    }
  }

  [pscustomobject]@{
    Name = $u.Name
    SamAccountName = $u.SamAccountName
    Title = $u.Title
    Before = $before
    After = if ($changed) { $after } else { $before }
    Changed = [bool]$changed
  }
}

$report | Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation
Write-Host "Wrote: $OutputCsvPath"

