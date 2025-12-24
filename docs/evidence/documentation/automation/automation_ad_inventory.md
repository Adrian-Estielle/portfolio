# Directory Services / AD onboarding automation — inventory (sanitized)

This inventory summarizes a recovered set of Active Directory onboarding/maintenance scripts (ExampleOrg-era) and the curated subset published to the Evidence Archive.

Public-safe note:
- The **private** inventory contains local file paths and identifier signals; it is stored outside the repo.
- The **published** evidence below contains sanitized content only (no internal domains, OU/group names, usernames, or secrets).

## Published artifacts (curated)

| Artifact | Type | Purpose (1 line) | Confidence |
|---|---|---|---|
| [`ad_new-user_from-title-mapping.ps1`](../../view/automation/021__A5A5D52F07__ad_new-user_from-title-mapping.ps1.html) · [raw](../../scripts/automation/021__A5A5D52F07__ad_new-user_from-title-mapping.ps1) | script | Creates a new AD user and assigns groups via a title→groups CSV mapping. | high |
| [`ad_ou_export_user-groups_operations.ps1`](../../view/automation/022__2E5301CF47__ad_ou_export_user-groups_operations.ps1.html) · [raw](../../scripts/automation/022__2E5301CF47__ad_ou_export_user-groups_operations.ps1) | script | Exports OU-scoped users and their group memberships (Operations example). | high |
| [`ad_ou_export_user-groups_project-advisors.ps1`](../../view/automation/023__8F6611C13C__ad_ou_export_user-groups_project-advisors.ps1.html) · [raw](../../scripts/automation/023__8F6611C13C__ad_ou_export_user-groups_project-advisors.ps1) | script | Exports OU-scoped users and their group memberships (Project Advisors example). | high |
| [`ad_ou_export_name-title-description.ps1`](../../view/automation/024__DBBA2C29CD__ad_ou_export_name-title-description.ps1.html) · [raw](../../scripts/automation/024__DBBA2C29CD__ad_ou_export_name-title-description.ps1) | script | Exports Name/Title/Description for users under a target OU (Subtree) to CSV. | high |
| [`ad_create_test-users_30.ps1`](../../view/automation/025__F5A3E559D0__ad_create_test-users_30.ps1.html) · [raw](../../scripts/automation/025__F5A3E559D0__ad_create_test-users_30.ps1) | script | Creates test users to validate edge cases before running bulk updates. | high |
| [`ad_update-descriptions_temp-extra.ps1`](../../view/automation/026__6AB88E064D__ad_update-descriptions_temp-extra.ps1.html) · [raw](../../scripts/automation/026__6AB88E064D__ad_update-descriptions_temp-extra.ps1) | script | Normalizes user Description values and writes a before/after report (dry-run unless `-Apply`). | high |
| [`ad_update-descriptions_v2-only-ou.ps1`](../../view/automation/027__9FDB37817C__ad_update-descriptions_v2-only-ou.ps1.html) · [raw](../../scripts/automation/027__9FDB37817C__ad_update-descriptions_v2-only-ou.ps1) | script | OU-scoped Description normalization + report (dry-run unless `-Apply`). | high |
| [`ad_update-descriptions_v2.ps1`](../../view/automation/028__A9DE623869__ad_update-descriptions_v2.ps1.html) · [raw](../../scripts/automation/028__A9DE623869__ad_update-descriptions_v2.ps1) | script | Broad-scope Description normalization + report (dry-run unless `-Apply`). | high |
| [`ad_update-descriptions_v3-ou-subtree.ps1`](../../view/automation/029__5933227B9A__ad_update-descriptions_v3-ou-subtree.ps1.html) · [raw](../../scripts/automation/029__5933227B9A__ad_update-descriptions_v3-ou-subtree.ps1) | script | Subtree Description normalization with LOA-marker preservation. | high |
| [`ad_export_descriptions_before.ps1`](../../view/automation/030__B317E28762__ad_export_descriptions_before.ps1.html) · [raw](../../scripts/automation/030__B317E28762__ad_export_descriptions_before.ps1) | script | Snapshot export (before) for change validation. | high |
| [`ad_export_descriptions_after.ps1`](../../view/automation/031__2BC055E829__ad_export_descriptions_after.ps1.html) · [raw](../../scripts/automation/031__2BC055E829__ad_export_descriptions_after.ps1) | script | Snapshot export (after) for change validation. | high |

## Notes

- The curated set is intentionally OU-scoped and validation-focused: export → change (dry-run first) → export → compare.
- The private candidate inventory (not published) includes additional department-scoped variants and duplicates from backups.

