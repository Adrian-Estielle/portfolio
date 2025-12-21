# Windows Baseline Audit (Portfolio Script)

A small, read-only PowerShell script that collects baseline info and outputs a single HTML report.

This is useful as a work sample because it demonstrates:
- Troubleshooting discipline (capture state consistently)
- "Validation evidence" mindset (logs/config baselines)
- Clear output that can be attached to a ticket/runbook

## Run
```powershell
pwsh -File .\Invoke-WindowsBaselineAudit.ps1 -OutputPath .\baseline_report.html
```

Open `baseline_report.html` in a browser.
