# Field Notes / KB — Outline

**Legend**
- * = under active development / expanding

## Endpoint runbooks*
- Autopilot enrollment checklist + recovery (network stability, MFA readiness, recovery from half-state)
- Intune “Not compliant” triage:
  - check-in / stale inventory first
  - remediate BitLocker/Secure Boot/Firewall/Defender/OS min/local admin drift
  - Conditional Access emergency access path (break-glass)
- Auto-sync SharePoint libraries to File Explorer (Intune + OneDrive):
  - copy library ID
  - Unicode → normal string conversion
  - assign to Entra group
  - validation flow
- OEM cleanup baseline (HP/Lenovo patterns)

## Automation runbooks*
- Onboarding: minimal inputs → create user + groups (role/region matrix), base license rule (Office + Email)
- Offboarding/termination: disable + revoke, auto-reply directs to manager, delegation where authorized, OU move, timed deletion, approvals for MFA clears
- Mapped drive self-heal
- Teams chatbot triage (display/dock driver reset)
- CI runbooks: GitHub Actions + Jenkins Windows agent

## Migration runbooks*
- Pre-seed + delta sync (minimize cutover), permission validation with real user contexts
- Excel hyperlink remediation tool (safe, auditable, parameterized old→new, unhide/rehide, preserve timestamps)
- Performance monitoring note (region + churn can break assumptions)

## Cheat sheets*
- Permissions precedence: RBAC vs sharing vs NTFS inheritance (common traps)
- Diagrams (Razzberry flow, DFS vs SharePoint sync, onboarding lead time)