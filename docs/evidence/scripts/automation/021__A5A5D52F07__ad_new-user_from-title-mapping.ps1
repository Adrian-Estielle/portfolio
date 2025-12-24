# Sanitized artifact (021)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Creates a new Active Directory user in a target OU.
- Resolves a manager account (optional).
- Adds group memberships based on a Title → Group mapping CSV.

When used
- AD-driven onboarding where role/title determines baseline group membership.

Inputs
- DomainControllerFqdn: DC hostname/FQDN (optional; auto-discovery fallback).
- FirstName / LastName / Title: used to build the account and select groups.
- GroupsMappingCsvPath: CSV with columns `Title` and `Group`.
- UserOuDn OR (Office + Department + BaseDn): where the user is created.
- ManagerIdentity: samAccountName/UPN/DN to set `manager` (optional).
- InitialPassword: SecureString; never hard-code passwords.

Safety notes
- Supports `-WhatIf` / `-Confirm`.
- Use delegated rights (least privilege), not Domain Admin.
- Prefer `-ChangePasswordAtLogon $true` for new users.

Validation
- Confirm user exists, is enabled, and UPN/mail are correct.
- Confirm group membership matches the mapping CSV for the title.
- Confirm Manager/Title/Department/Office attributes are set as expected.

What was sanitized
- Internal domains replaced with `example.org`.
- OU/DN structure replaced with placeholders/parameters.
- Hard-coded password and local file paths removed.
- Original local filename: `new user test 03.ps1`.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [string]$DomainControllerFqdn,

  [string]$FirstName,
  [string]$LastName,
  [string]$Title,
  [string]$ManagerIdentity,

  [string]$Office,
  [string]$Department,
  [string]$UserOuDn,
  [string]$BaseDn = 'DC=example,DC=org',

  [string]$UserPrincipalNameSuffix = 'example.org',
  [string]$MailDomain = 'example.org',

  [string]$GroupsMappingCsvPath = (Join-Path -Path $PSScriptRoot -ChildPath 'groups-mapping.example.csv'),

  [SecureString]$InitialPassword,
  [bool]$ChangePasswordAtLogon = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

function Read-Optional([string]$Value, [string]$Prompt) {
  if ($Value) { return $Value }
  return (Read-Host -Prompt $Prompt)
}

if (-not $DomainControllerFqdn) {
  $DomainControllerFqdn = Read-Host -Prompt 'Domain controller FQDN (leave blank to auto-discover)'
}
if (-not $DomainControllerFqdn) {
  $DomainControllerFqdn = (Get-ADDomainController -Discover -NextClosestSite).HostName
}

$FirstName = Read-Optional -Value $FirstName -Prompt 'First name'
$LastName  = Read-Optional -Value $LastName  -Prompt 'Last name'
$Title     = Read-Optional -Value $Title     -Prompt 'Job title (used for title→group mapping)'

if (-not $ManagerIdentity) {
  $ManagerIdentity = Read-Host -Prompt 'Manager identity (samAccountName/UPN/DN) (optional)'
}

if (-not $InitialPassword) {
  $InitialPassword = Read-Host -Prompt 'Initial password (SecureString)' -AsSecureString
}

if (-not (Test-Path -LiteralPath $GroupsMappingCsvPath)) {
  throw "Mapping CSV not found: $GroupsMappingCsvPath"
}

if (-not $UserOuDn) {
  if (-not $Office) { $Office = Read-Host -Prompt 'Office (used to construct OU)' }
  if (-not $Department) { $Department = Read-Host -Prompt 'Department (used to construct OU)' }
  if (-not $Office -or -not $Department) {
    throw 'Provide -UserOuDn OR provide both -Office and -Department to construct a DN.'
  }
  $UserOuDn = "OU=$Department,OU=Users,OU=$Office,$BaseDn"
}

$mapping = Import-Csv -LiteralPath $GroupsMappingCsvPath
$rawGroups = $mapping | Where-Object { $_.Title -eq $Title } | Select-Object -ExpandProperty Group
$groups = @(
  $rawGroups |
    Where-Object { $_ -and $_.ToString().Trim() } |
    ForEach-Object { $_.ToString().Trim() } |
    Sort-Object -Unique
)

if ($groups.Count -lt 1) {
  throw "No groups found for Title='$Title' in $GroupsMappingCsvPath"
}

$displayName = "$FirstName $LastName"
$sam = (($FirstName.Substring(0, 1) + $LastName) -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
$upn = "$sam@$UserPrincipalNameSuffix"
$mail = "$sam@$MailDomain"

$managerDn = $null
if ($ManagerIdentity) {
  try {
    $managerDn = (Get-ADUser -Identity $ManagerIdentity -Server $DomainControllerFqdn -ErrorAction Stop).DistinguishedName
  } catch {
    Write-Warning "Manager lookup failed for '$ManagerIdentity' (continuing without -Manager): $($_.Exception.Message)"
  }
}

Write-Host "Target OU: $UserOuDn"
Write-Host "Groups for '$Title':"
$groups | ForEach-Object { Write-Host " - $_" }

if (-not $PSCmdlet.ShouldProcess($displayName, "Create AD user ($sam)")) {
  Write-Host "WhatIf: would create '$displayName' and add $($groups.Count) group(s)."
  return
}

$newUserParams = @{
  Name                  = $displayName
  GivenName             = $FirstName
  Surname               = $LastName
  SamAccountName        = $sam
  UserPrincipalName     = $upn
  EmailAddress          = $mail
  Title                 = $Title
  Department            = $Department
  Office                = $Office
  Path                  = $UserOuDn
  AccountPassword       = $InitialPassword
  Enabled               = $true
  ChangePasswordAtLogon = [bool]$ChangePasswordAtLogon
  Server                = $DomainControllerFqdn
  PassThru              = $true
}
if ($managerDn) { $newUserParams.Manager = $managerDn }

$user = New-ADUser @newUserParams

foreach ($g in $groups) {
  if ($PSCmdlet.ShouldProcess($g, "Add member $sam")) {
    Add-ADGroupMember -Identity $g -Members $user -Server $DomainControllerFqdn
  }
}

$created = Get-ADUser -Identity $user -Server $DomainControllerFqdn -Properties UserPrincipalName,Title,Department,Office,Enabled,Manager,mail
$created | Select-Object Name,SamAccountName,UserPrincipalName,mail,Title,Department,Office,Enabled,Manager | Format-List

