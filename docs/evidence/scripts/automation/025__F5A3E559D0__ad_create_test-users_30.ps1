# Sanitized artifact (025)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
What it does
- Creates a batch of test users in a target OU and assigns varied Description values.

When used
- Testing Description-normalization rules, OU scoping, and downstream tooling without touching real users.

Inputs
- TargetOuDn: OU where test accounts will be created.
- DomainControllerFqdn: DC hostname/FQDN (optional).
- Count: number of accounts to create (default: 30).
- InitialPassword: SecureString.
- UserPrincipalNameSuffix / MailDomain: where UPN/mail are formed.

Safety notes
- Destructive: creates accounts. Defaults to dry-run unless `-Apply` (or `-WhatIf`).
- Supports `-WhatIf` / `-Confirm`.

Validation
- Verify the expected number of users exist in the test OU.
- Verify Description distribution matches the intended edge cases.
- Clean up test accounts after validation (disable/delete per policy).

What was sanitized
- Internal domains, OU paths, and hard-coded password removed.
- Original local filename: `Test 30 users 01.ps1`.
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
  [string]$DomainControllerFqdn,
  [Parameter(Mandatory = $true)]
  [string]$TargetOuDn = 'OU=<TEST_ACCOUNTS>,OU=Users,DC=example,DC=org',
  [int]$Count = 30,
  [string]$NamePrefix = 'Test',
  [string]$LastName = 'ScriptTestUser',
  [string]$UserPrincipalNameSuffix = 'example.org',
  [string]$MailDomain = 'example.org',
  [SecureString]$InitialPassword,
  [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

Import-Module ActiveDirectory -ErrorAction Stop

if ($DomainControllerFqdn) {
  $PSDefaultParameterValues['*-AD*:Server'] = $DomainControllerFqdn
}

if (-not $InitialPassword) {
  $InitialPassword = Read-Host -Prompt 'Initial password (SecureString)' -AsSecureString
}

if (-not $Apply -and -not $WhatIfPreference) {
  Write-Warning "Dry run: no accounts will be created. Re-run with -Apply (or use -WhatIf to preview actions)."
}

$randomWords = @('accountant','corporate','finance','maintenance','support','analyst','manager','engineer','operator','contractor','vendor','tester')
$rng = [System.Random]::new()

function New-RandomTail([int]$MinWords = 1, [int]$MaxWords = 3) {
  $count = $rng.Next($MinWords, $MaxWords + 1)
  $words = for ($i = 0; $i -lt $count; $i++) { $randomWords[$rng.Next(0, $randomWords.Count)] }
  return ($words -join ' ')
}

for ($i = 0; $i -lt $Count; $i++) {
  $firstName = '{0}{1:00}' -f $NamePrefix, $i
  $sam = (($firstName.Substring(0,1) + '.' + $LastName.Substring(0, [Math]::Min(5, $LastName.Length))) -replace '[^A-Za-z0-9\\.]','').ToLowerInvariant()
  $upn = "$sam@$UserPrincipalNameSuffix"
  $mail = "$sam@$MailDomain"

  $desc = ''
  if ($i -lt 5)      { $desc = "Consultant $(New-RandomTail 1 2)" }
  elseif ($i -lt 10) { $desc = "Temp $(New-RandomTail 1 2)" }
  elseif ($i -lt 25) { $desc = " $(New-RandomTail 1 3)".Trim() }
  elseif ($i -eq 27) { $desc = 'Test' }
  elseif ($i -eq 28) { $desc = 'Vendor' }
  elseif ($i -eq 29) { $desc = 'Testing' }

  $plan = [pscustomobject]@{
    Name = "$firstName $LastName"
    SamAccountName = $sam
    UserPrincipalName = $upn
    Mail = $mail
    Description = $desc
  }

  if (-not $Apply -and -not $WhatIfPreference) {
    $plan
    continue
  }

  if ($PSCmdlet.ShouldProcess($plan.SamAccountName, "Create test user in $TargetOuDn")) {
    New-ADUser -Name $plan.Name `
      -GivenName $firstName `
      -Surname $LastName `
      -SamAccountName $plan.SamAccountName `
      -UserPrincipalName $plan.UserPrincipalName `
      -EmailAddress $plan.Mail `
      -Path $TargetOuDn `
      -Enabled $true `
      -PasswordNeverExpires $true `
      -ChangePasswordAtLogon $false `
      -AccountPassword $InitialPassword `
      -Description $plan.Description | Out-Null
  }
}

Write-Host "Done. (Dry-run=$(-not $Apply -and -not $WhatIfPreference))"

