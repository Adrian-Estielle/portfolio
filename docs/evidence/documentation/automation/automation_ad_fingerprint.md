# Directory Services / AD onboarding automation — fingerprint (public-safe)

This note describes the shared **behavioral fingerprints** I used to identify a cluster of “same-era” PowerShell scripts focused on Active Directory onboarding and maintenance.

Public-safe note:
- This document intentionally avoids org-specific identifiers (domains, OU paths, group names, server names, usernames, file shares, private URLs).
- Published scripts are sanitized and replace identifiers with placeholders such as `<REDACTED_*>` and `example.org`.

## Shared signals (what these scripts have in common)

**Base signals (AD tooling):**
- Active Directory cmdlet usage (ex: `Get-ADUser`, `New-ADUser`, `Set-ADUser`, group membership cmdlets).
- Optional `-Server` / “target DC” handling for deterministic runs.

**High-confidence behavior signals (workflow patterns):**
- **OU-scoped operations** using `-SearchBase` and `-SearchScope` (OneLevel vs Subtree) to reduce blast radius.
- **CSV-driven automation** (ex: role/title → group mapping, user export reports).
- **Before/after evidence exports** to validate changes (snapshot → change → snapshot → compare).
- **Dry-run safety rails** (ex: `SupportsShouldProcess`, `-WhatIf`, `-Confirm`, and explicit `-Apply` switches).

**Normalization/cleanup patterns:**
- Controlled normalization of attributes such as `Description` (with special-case handling like LOA/test/vendor/temp markers).
- Repeatable reporting (CSV outputs) to catch false positives before applying changes broadly.

## How I used this fingerprint (in recovery mode)

I treated a small set of “anchor” scripts (clearly AD onboarding/maintenance) as the truth set, then searched for additional scripts that matched:
- The same cmdlet combinations (ex: `Get-ADUser` + OU-scoped search + CSV export).
- Similar safety patterns (dry-run by default, explicit apply, `ShouldProcess`).
- Similar naming conventions and “export → update → export” workflows.

## Related artifacts

- Inventory: `docs/evidence/documentation/automation/automation_ad_inventory.md`

