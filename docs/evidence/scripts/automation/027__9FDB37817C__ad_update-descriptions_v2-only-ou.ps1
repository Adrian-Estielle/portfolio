# Sanitized artifact (027)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Normalizes user `Description` values within a target OU (optionally Subtree) and exports a before/after CSV report.

When used
- Running cleanup safely against a known OU (ex: a test-accounts OU) instead of the whole domain.

Inputs
- TargetOuDn: DN of the OU to scan.
- SearchScope: OneLevel or Subtree.
- Apply: actually writes changes; otherwise produces a dry-run report.
- OutputCsvPath: where to write the report CSV.

Safety notes
- Defaults to dry-run (no AD writes) unless `-Apply` (or `-WhatIf`).
- Supports `-WhatIf` / `-Confirm`.

Validation
- Confirm the OU scope is correct and the count of affected users is expected.
- Review the report CSV for false positives before applying broadly.

What was sanitized
- Internal DC/OU identifiers and output paths removed.
- Original local filename: `update descriptions V2 Only OU.ps1`.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [string]$DomainControllerFqdn,
  [Parameter(Mandatory = $true)]
  [string]$TargetOuDn = 'OU=<TARGET_OU>,DC=example,DC=org',
  [ValidateSet('OneLevel','Subtree')]
  [string]$SearchScope = 'Subtree',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'description_changes_target_ou.csv'),
  [switch]$Apply
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
  if ($Description -match 'consultant') { return 'Consultant' }
  if ($Description -match 'contractor') { return 'Contractor' }
  if ($Description -match 'temp') { return 'Temp' }
  if ($Description -match 'vendor') { return 'Vendor' }
  if ($Description -match 'test|testing') { return 'Test Account' }
  return 'Full Time'
}

if (-not $Apply -and -not $WhatIfPreference) {
  Write-Warning "Dry run: no AD changes will be applied. Re-run with -Apply (or use -WhatIf to preview actions)."
}

$users = Get-ADUser -Filter * -SearchBase $TargetOuDn -SearchScope $SearchScope -Property Description,Title,SamAccountName
$total = $users.Count
$count = 0

$report = foreach ($u in $users) {
  $count++
  Write-Progress -Activity 'Normalizing user descriptions' -Status "$count/$total" -PercentComplete (($count / [Math]::Max(1,$total)) * 100)

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

