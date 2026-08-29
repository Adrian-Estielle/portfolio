# Adrian Charbonneau — Systems & Infrastructure Engineering Portfolio

Senior systems / infrastructure engineer focused on Windows, Active Directory / Entra ID, Microsoft 365, Azure, endpoint management, automation, and enterprise migrations.

This repository is a curated collection of sanitized work samples, technical runbooks, scripts, validation artifacts, and small reproducible projects. The goal is to show how I approach infrastructure work in practice: understand the environment, reduce manual effort, validate changes, document the result, and leave the system easier to operate.

## Portfolio site

**https://adrian-estielle.github.io/portfolio/**

## Selected areas

- **Windows & Identity** — Active Directory, Group Policy, DNS/DHCP, Entra ID, identity lifecycle, authentication and access troubleshooting
- **Cloud & Microsoft 365** — Azure infrastructure, Exchange Online, Teams, SharePoint, OneDrive, hybrid identity and migration work
- **Endpoint Engineering** — Intune, Autopilot, Jamf, BitLocker, compliance baselines, deployment and remediation
- **Automation** — PowerShell, Batch, C#, Python, Microsoft Graph and repeatable administrative tooling
- **Validation & Operations** — production-mirroring labs, pre/post checks, rollback planning, runbooks and evidence-driven troubleshooting

## Featured work

### Identity lifecycle automation
Sanitized runbooks and PowerShell patterns for HR-driven provisioning, Active Directory maintenance, scoping, validation and rollback.

- [Workday → Entra ID provisioning runbook](docs/kb/automation_workday_to_entra_id_provisioning.html)
- [Workday → Active Directory provisioning runbook](docs/kb/automation_workday_to_active_directory_provisioning.html)
- [AD replication preflight](docs/kb/automation_ad_replication_preflight.html)

### Windows upgrade validation
A sanitized end-to-end validation pattern for Windows upgrade packages: coverage matrix, preflight, upgrade, workflow/peripheral validation, rollback and release gating.

- [Endpoint / upgrade documentation](docs/evidence/endpoint.html)
- [Field notes](docs/notes.html#kb-upgrade-validation-sqe-signoff)

### Windows baseline audit
A read-only PowerShell project that captures security- and operations-relevant configuration and produces a shareable report artifact.

- [Project](projects/WindowsBaselineAudit/)
- [Sample report](docs/reports/baseline_report.html)

### CI/CD demonstration
A small .NET build/test/package pipeline implemented with GitHub Actions and Jenkins to demonstrate reproducible build automation and observable outputs.

- [HelloBuild project](projects/HelloBuild/)
- [CI runbook](docs/kb/ci.html)

## Technical notes and evidence

- [Field Notes / KB](docs/notes.html)
- [Evidence archive](docs/evidence.html)
- [Project documentation](docs/evidence/documentation.html)
- [Project scripts](docs/evidence/scripts.html)

All portfolio artifacts are intended to be sanitized. Customer data, credentials, tenant identifiers, internal hostnames, and proprietary screenshots should not be present.

## Contact

- LinkedIn: https://www.linkedin.com/in/adrian-charbonneau-56a72114a
- GitHub: https://github.com/Adrian-Estielle
- Email: adrianestielle@protonmail.com
