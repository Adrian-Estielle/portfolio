<#
.SYNOPSIS
  Lightweight Windows baseline audit that produces a single HTML report.

.DESCRIPTION
  This is a portfolio-friendly script:
  - Read-only (no changes are made)
  - Collects common "enterprise baseline" signals (BitLocker, Defender, Firewall, Updates, Local Admins, etc.)
  - Outputs an HTML report you can attach or screenshot

  NOTE: This is not a full CIS benchmark scanner. It is meant as a clean, practical example
  of how you'd capture state for troubleshooting/validation/runbooks.

.USAGE
  PowerShell (Admin recommended):
    pwsh -File .\Invoke-WindowsBaselineAudit.ps1 -OutputPath .\baseline_report.html

.PARAMETER OutputPath
  Where to write the HTML report.

#>

param(
  [Parameter(Mandatory=$false)]
  [string]$OutputPath = ".\baseline_report.html"
)

$ErrorActionPreference = "Stop"

function Get-Section($title, $rows) {
  $html = "<h2>$title</h2>"
  if (-not $rows -or $rows.Count -eq 0) {
    return $html + "<p><em>No data</em></p>"
  }
  $html += "<table><thead><tr><th>Key</th><th>Value</th></tr></thead><tbody>"
  foreach ($r in $rows) {
    $k = [System.Web.HttpUtility]::HtmlEncode($r.Key)
    $v = [System.Web.HttpUtility]::HtmlEncode([string]$r.Value)
    $html += "<tr><td>$k</td><td><code>$v</code></td></tr>"
  }
  $html += "</tbody></table>"
  return $html
}

# Collect
$sections = @()

# Basic OS
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$sections += @{
  Title = "System"
  Rows = @(
    @{ Key="Computer Name"; Value=$env:COMPUTERNAME },
    @{ Key="User"; Value="$env:USERDOMAIN\$env:USERNAME" },
    @{ Key="Manufacturer"; Value=$cs.Manufacturer },
    @{ Key="Model"; Value=$cs.Model },
    @{ Key="OS"; Value=$os.Caption },
    @{ Key="Version"; Value=$os.Version },
    @{ Key="Build"; Value=$os.BuildNumber },
    @{ Key="Install Date"; Value=$os.InstallDate },
    @{ Key="Last Boot"; Value=$os.LastBootUpTime }
  )
}

# Updates (last 10)
try {
  $hotfix = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
  $rows = @()
  foreach ($h in $hotfix) {
    $rows += @{ Key=$h.HotFixID; Value=("InstalledOn: {0}" -f $h.InstalledOn) }
  }
  $sections += @{ Title="Recent Updates (Top 10)"; Rows=$rows }
} catch {
  $sections += @{ Title="Recent Updates (Top 10)"; Rows=@(@{Key="Error";Value=$_.Exception.Message}) }
}

# Firewall profiles
try {
  $fw = Get-NetFirewallProfile | Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction
  $rows = @()
  foreach ($p in $fw) {
    $rows += @{ Key=$p.Name; Value=("Enabled={0}; In={1}; Out={2}" -f $p.Enabled,$p.DefaultInboundAction,$p.DefaultOutboundAction) }
  }
  $sections += @{ Title="Windows Firewall"; Rows=$rows }
} catch {
  $sections += @{ Title="Windows Firewall"; Rows=@(@{Key="Error";Value=$_.Exception.Message}) }
}

# Defender status
try {
  $mp = Get-MpComputerStatus
  $rows = @(
    @{ Key="AM Service Enabled"; Value=$mp.AMServiceEnabled },
    @{ Key="Antispyware Enabled"; Value=$mp.AntispywareEnabled },
    @{ Key="Antivirus Enabled"; Value=$mp.AntivirusEnabled },
    @{ Key="Real-time Protection Enabled"; Value=$mp.RealTimeProtectionEnabled },
    @{ Key="NIS Enabled"; Value=$mp.NISEnabled },
    @{ Key="Signature Age (Days)"; Value=$mp.AntivirusSignatureAge }
  )
  $sections += @{ Title="Microsoft Defender"; Rows=$rows }
} catch {
  $sections += @{ Title="Microsoft Defender"; Rows=@(@{Key="Error";Value=$_.Exception.Message}) }
}

# BitLocker
try {
  $rows = @()
  $vols = Get-BitLockerVolume
  foreach ($v in $vols) {
    $rows += @{ Key=$v.MountPoint; Value=("Protection={0}; Encryption={1}; Status={2}" -f $v.ProtectionStatus,$v.EncryptionMethod,$v.VolumeStatus) }
  }
  $sections += @{ Title="BitLocker"; Rows=$rows }
} catch {
  $sections += @{ Title="BitLocker"; Rows=@(@{Key="Note";Value="BitLocker cmdlets not available or requires elevation."}) }
}

# Local Administrators
try {
  $admins = Get-LocalGroupMember -Group "Administrators" | Select-Object Name, ObjectClass, PrincipalSource
  $rows = @()
  foreach ($a in $admins) {
    $rows += @{ Key=$a.Name; Value=("Type={0}; Source={1}" -f $a.ObjectClass,$a.PrincipalSource) }
  }
  $sections += @{ Title="Local Administrators"; Rows=$rows }
} catch {
  $sections += @{ Title="Local Administrators"; Rows=@(@{Key="Error";Value=$_.Exception.Message}) }
}

# Build HTML
$style = @"
<style>
  body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; }
  h1 { margin-bottom: 6px; }
  .meta { color: #555; margin-top: 0; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 18px; }
  th, td { border: 1px solid #ddd; padding: 8px; vertical-align: top; }
  th { background: #f5f5f5; text-align: left; }
  code { white-space: pre-wrap; }
</style>
"@

$generated = Get-Date
$html = "<html><head><meta charset='utf-8'/>$style</head><body>"
$html += "<h1>Windows Baseline Audit</h1>"
$html += "<p class='meta'>Generated: $generated</p>"

foreach ($s in $sections) {
  $html += (Get-Section $s.Title $s.Rows)
}

$html += "</body></html>"

Set-Content -Path $OutputPath -Value $html -Encoding UTF8
Write-Host "✅ Report written to: $OutputPath"
