# Field Notes / KB — Outline

**Legend**
- * = under active development / expanding

## Pages
- Endpoint: docs/kb/endpoint.html
- Automation: docs/kb/automation.html
- Migration: docs/kb/migration.html
- Cheat sheets: docs/kb/cheatsheets.html
- CI runbook: docs/kb/ci.html

## Requested corrections applied
- Teams bot triage:
  - still creates Zendesk ticket for documentation
  - auto-documents + resolves if fix works
  - uses Windows Troubleshoot-style detection signals
- Migration:
  - wave strategy starts with low-dependency groups first
  - lifecycle tiering: SharePoint (live) → Azure Files (cold, IT-only, ticket) → Blob (deep archive)
  - Excel hyperlink purge is done BEFORE migration, removing ALL hyperlinks to avoid tool bog-down
- Permissions:
  - SMB effective access = Share permissions ∩ NTFS (most restrictive wins)
  - SharePoint “sharing links” are additive grants and can create sprawl
- Diagrams:
  - moved to docs/_draft/diagrams.html and not linked