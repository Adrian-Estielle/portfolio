# Sanitized artifact (028)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Normalizes user `Description` values across a broader directory scope and exports a before/after CSV report.

When used
- When Description values must be standardized (Full Time / Temp / Contractor / Vendor / Test) for downstream automation.

Inputs
- SearchBaseDn: DN where the search begins (default: domain root placeholder).
- Apply: actually writes changes; otherwise produces a dry-run report.
- OutputCsvPath: where to write the report CSV.

Safety notes
- Defaults to dry-run (no AD writes) unless `-Apply` (or `-WhatIf`).
- Supports `-WhatIf` / `-Confirm`.

Validation
- Review report output for false positives.
- Roll back strategy: restore from report CSV (or run a revert script) if needed.

What was sanitized
- Internal DC/domain identifiers and output paths removed.
- Original local filename: `update descriptions v2.ps1`.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [string]$DomainControllerFqdn,
  [string]$SearchBaseDn = 'DC=example,DC=org',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'description_changes_domain.csv'),
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
  if ($Description -match 'loa') { return $Description } # preserve LOA-like markers
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

$users = Get-ADUser -Filter * -SearchBase $SearchBaseDn -Property Description,Title,SamAccountName
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

