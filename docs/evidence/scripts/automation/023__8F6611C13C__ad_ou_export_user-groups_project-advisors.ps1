# Sanitized artifact (023)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Exports users from a target OU and captures their Title + group memberships.

When used
- Building a role/group baseline for a team OU (audit before onboarding changes).

Inputs
- DomainControllerFqdn: DC hostname/FQDN (optional).
- TargetOuDn: distinguishedName of the OU to query.
- OutputCsvPath: where to write the CSV.

Safety notes
- Read-only against AD; writes a local CSV output.

Validation
- Open the CSV and spot-check a handful of users against ADUC / Get-ADUser.
- Confirm OU scope (OneLevel vs Subtree) is intentional.

What was sanitized
- Internal DC hostnames, OU DNs, and usernames removed (now parameters/placeholders).
- Original local filename: `Project Advisors.ps1`.
#>

[CmdletBinding()]
param(
  [string]$DomainControllerFqdn,
  [Parameter(Mandatory = $true)]
  [string]$TargetOuDn = 'OU=<TEAM>,OU=Users,DC=example,DC=org',
  [string]$OutputCsvPath = (Join-Path -Path (Get-Location) -ChildPath 'project_advisors_user_groups.csv')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

$users = Get-ADUser -Filter * -SearchBase $TargetOuDn -SearchScope Subtree -Properties Title

$results = foreach ($user in $users) {
  $groups = Get-ADPrincipalGroupMembership -Identity $user | Select-Object -ExpandProperty Name
  [pscustomobject]@{
    Name  = $user.Name
    Title = $user.Title
    Groups = ($groups -join ';')
  }
}

$results | Export-Csv -LiteralPath $OutputCsvPath -NoTypeInformation
Write-Host "Wrote: $OutputCsvPath"

