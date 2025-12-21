# Field Notes / KB — Outline

These notes are the “hub” for runbooks and scenario write-ups that support the portfolio projects and the roles I’m targeting.

**Legend**
- `*` = under active development / expanding

---

## Endpoint runbooks*

### Windows Autopilot: reliable enrollment checklist + recovery paths
- Pre-req validation: licensing, group assignment, profile targeting, required apps/policies
- Network stability requirements for OOBE (prefer Ethernet; avoid weak Wi‑Fi)
- MFA readiness before first sign-in to avoid dead-ends
- Recovery pattern when enrollment lands in a broken / half-complete state:
  - remove stale device records (Intune / Entra where appropriate)
  - re-enroll from clean OOBE (wipe/reinstall as needed)
- OOBE troubleshooting: Shift+F10 command prompt (connectivity checks)

### Intune: “Not compliant” device triage (Windows / iOS / Android)
- Identify failing setting(s), confirm device check-in health
- Remediate by category:
  - Windows: BitLocker/TPM/Secure Boot, firewall, Defender, OS patch level, local admin drift
  - iOS/Android: OS minimum, passcode/integrity, device health signals
- Verify re-evaluation and avoid chasing stale inventory

### SharePoint library auto-sync: Intune + OneDrive auto-mount
- Pattern: Entra group = access unit, SharePoint permissions aligned
- Scripted retrieval of site/library identifiers to scale cleanly
- Intune OneDrive policy: silent sign-in + auto-mount libraries
- Validation: add user to group → sign in → library appears in Explorer

### OEM bloatware cleanup baseline (HP / Lenovo examples)
- Inventory by manufacturer/model → allow-list vs remove-list
- Automate removals via Intune (not manual)
- Regression checks for drivers/app stability

---

## Automation runbooks*

### Onboarding automation: minimal inputs → complete user + access baseline
- Generate UPN/email from convention; collision checks
- Create user + attributes; set manager
- Assign groups via role/region matrix (replaces “copy another user”)
- License/mailbox actions; output summary/log

### Offboarding / termination automation: revoke access fast + preserve required data
- Disable sign-in + revoke sessions
- Litigation hold / retention-aligned actions
- Mailbox delegation/auto-replies (authorized)
- Strip roles/groups; move to terminated container
- Deferred deletion with approvals for irreversible steps (MFA factor clears, etc.)

### Mapped drive “self-heal” automation
- Detect known-bad mappings; remove; clear stale creds; re-map; log
- Pair with permission audits when root cause is ACL drift

### CI runbook: GitHub Actions — HelloBuild
- restore → build → test → package → upload artifact
- strong portfolio proof: observable run + reproducible artifact

### CI runbook: Jenkins controller (Docker) + Windows inbound agent (WebSocket)
- docker-run controller with persistent volume
- create inbound node; copy exact agent command from UI
- ensure tools exist on the agent (pwsh/dotnet/git/java)
- ensure pipeline actually targets the agent (label or built-in executors = 0)
- “main vs master” branch gotcha

---

## Migration runbooks*

### Pre-seed + delta sync strategy
- Inventory, partition active/archive, identify high-risk file types
- Pre-seed bulk early; delta sync periodically; final delta at cutover
- Validate permissions with real user contexts

### Excel hyperlink remediation tool (bulk)
- Work on copies for dev/testing
- Unhide/rehide sheets; parameterized old→new mapping
- Avoid breaking formulas/non-target links
- Preserve timestamps where required
- Produce logs and validate on a representative subset

---

## Cheat sheets*

### Permissions: RBAC vs sharing vs NTFS precedence
- RBAC = admin control plane
- Sharing = resource access (can sprawl)
- NTFS/inheritance/nesting = where mystery access issues are born
- Prefer simplification over endless exceptions
