# Adrian Charbonneau — Systems & Infrastructure Engineering Portfolio

Senior systems / infrastructure engineer focused on Windows, Active Directory / Entra ID, Microsoft 365, Azure, endpoint management, automation, and enterprise migrations.

This repository is a curated collection of sanitized case studies, technical runbooks, scripts, validation artifacts, and small reproducible projects. The goal is to show how I approach infrastructure work in practice: understand the environment, reduce manual effort, validate changes, document the result, and leave the system easier to operate.

## Portfolio site

**https://adrian-estielle.github.io/portfolio/**

For a quick review, start with the [case studies](docs/case-studies.html). For implementation detail, use the [runbooks / field notes](docs/notes.html) and [technical evidence](docs/evidence.html).

## Core areas

- **Windows & Identity** — Active Directory, Group Policy, DNS/DHCP, Windows Server, Entra ID, identity lifecycle, authentication and access troubleshooting
- **Cloud & Microsoft 365** — Azure infrastructure, Exchange Online, Teams, SharePoint, OneDrive, hybrid identity, backup/DR, monitoring and migration work
- **Endpoint Engineering** — Intune, Autopilot, Jamf, BitLocker, compliance baselines, deployment and remediation
- **Automation** — PowerShell, Batch, C#, Python, Microsoft Graph and repeatable administrative tooling
- **Validation & Operations** — production-mirroring labs, pre/post checks, rollback planning, runbooks and evidence-driven troubleshooting

## Selected case studies

- [Infrastructure ownership](docs/case-studies/infrastructure-ownership.html) — identity, M365, endpoint, Azure, legacy Windows workloads, backup/monitoring and automation as one operating environment
- [3+ TB accounting storage modernization](docs/case-studies/accounting-storage-modernization.html) — Azure Files, SharePoint, Blob, DFS/Azure File Sync, Kerberos, LinkFixer, PowerShell and architecture revision after testing
- [Windows upgrade engineering & validation](docs/case-studies/windows-upgrade-validation.html) — production-mirroring labs, automation, peripheral/workflow checks, restore testing and release gating
- [HR-driven identity provisioning](docs/case-studies/identity-provisioning.html) — Workday, Entra ID / Active Directory, matching, scope, role/group assignment, logging and directory safety checks

## Reproducible projects

### Windows baseline audit
A read-only PowerShell project that captures security- and operations-relevant configuration and produces a shareable report artifact.

- [Project](projects/WindowsBaselineAudit/)
- [Sample report](docs/reports/baseline_report.html)

### CI/CD demonstration
A small .NET build/test/package pipeline implemented with GitHub Actions and Jenkins to demonstrate reproducible build automation and observable outputs.

- [HelloBuild project](projects/HelloBuild/)
- [CI runbook](docs/kb/ci.html)

## Technical documentation and evidence

- [Runbooks / Field Notes](docs/notes.html)
- [Technical evidence hub](docs/evidence.html)
- [Technical documentation](docs/evidence/documentation.html) — original-format sanitized PDFs are the primary document links; browser-readable transcripts are secondary
- [Project scripts](docs/evidence/scripts.html)

Published artifacts are sanitized. Customer data, credentials, tenant identifiers, internal hostnames, private URLs, and proprietary screenshots should not be present.

## Contact

- LinkedIn: https://www.linkedin.com/in/adrian-charbonneau-56a72114a
- GitHub: https://github.com/Adrian-Estielle
- Email: adrianestielle@protonmail.com
