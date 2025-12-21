# Portfolio content outline (proof-first)

This document is the working blueprint for the portfolio repo + GitHub Pages site.
Goal: **proof-first**, recruiter-skimmable, and aligned to these target roles:

1. Modern Workplace / M365 Endpoint Architect  
2. Endpoint Management Engineer (Intune / Jamf)  
3. Systems Administrator / Endpoint Engineer  
4. Cloud Engineer (Azure / M365)  
5. Azure Migration / Infrastructure Engineer  
6. Solutions Architect / Systems Engineer  
7. Build & Release / Deployment Automation Engineer  
8. IT Support Specialist  
9. Platform / Automation Engineer (Scripting & Tooling)  

---

## 0) What exists today (already “real proof”)

### Portfolio site
- `docs/index.html` is the landing page (GitHub Pages)
- **Real screenshots** already placed:
  - `docs/images/jenkins_pipeline.png` (HelloBuild CI proof)
  - `docs/images/baseline_report.png` (Baseline audit proof)
- **Downloadable sample report**:
  - `docs/assets/baseline_report_sample.html` linked from Baseline card (better than a screenshot)

### CI proof wiring
- GitHub Actions workflow exists and uploads artifacts (HelloBuild)
- Jenkins pipeline exists and runs against the repo
- Jenkins validation is **not theoretical**; it’s tied to an actual pipeline run + screenshot

---

## 1) Repository hierarchy (current + intended)

### Current core structure (high confidence)
- `.github/workflows/`  
  - HelloBuild CI workflow (green run + artifacts)
- `Jenkinsfile`  
  - HelloBuild pipeline definition
- `docs/` (GitHub Pages root)
  - `index.html` (landing page)
  - `images/` (proof screenshots)
  - `assets/` (downloadable proof artifacts)
- `projects/HelloBuild/`
  - .NET solution + build script + `artifacts/` output

### Intended additions (public, sanitized)
- `docs/notes.html` *(public)*  
  - Endpoint / Automation / Migration / Cheat Sheet sections (runbook style)
- `docs/beyond.html` *(public)*  
  - “In progress” experiments / future writeups
- `docs/outline.md` *(internal blueprint, but harmless if public)*  
- Optional: `docs/assets/resume.pdf` *(public, redacted)*  
  - One-page PDF, no address; contact via GitHub/email

---

## 2) Landing page hierarchy (docs/index.html)

The landing page should read in this order:

1) **Hero / headline**
   - Who you are + what you build (endpoint + automation + migrations)

2) **Proof-first projects**
   - HelloBuild (CI proof: GitHub Actions + Jenkins)
   - Windows baseline audit (security/tooling proof: HTML report + screenshot + downloadable sample)

3) **Field Notes / Runbooks strip** (*starred*)
   - Endpoint notes*
   - Automation notes*
   - Migration notes*
   - Cheat sheet*
   - Beyond*

4) **Asterisk disclaimer (required)**
   - “* Sections marked with an asterisk are under active development…”

5) **About**
   - 2–3 lines max, no fluff, recruiter-skimmable

6) **Focus areas**
   - 3 bullets that map cleanly to your 9 titles:
     - Endpoint lifecycle
     - Automation / tooling
     - Migration / infrastructure

7) **Contact**
   - GitHub + email + LinkedIn (optional)

---

## 3) Field Notes / Runbooks hierarchy (notes.html)

These are written like an engineer’s playbook, not “AI tutoring.”

### A) Endpoint notes* (Intune / Jamf / Modern Workplace)
**1. Autopilot / enrollment + early-life reliability**
- Preconditions checklist:
  - User has MFA enrolled **before** first sign-in (prevents “stuck/offline identity” headaches)
  - Stable network during OOBE (hardwired if possible)
  - BIOS/firmware baseline: secure boot/TPM enabled (BitLocker compliance)
  - Naming conventions, group tags, and profile assignments confirmed

- Practical failure modes + what I do:
  - **User signs in too early (MFA not set)** → enrollment can land in an inconsistent state  
    - Approach: clean up device records (Intune/AAD), then re-enroll cleanly
  - **Network drops during OOBE** → can create “half-registered” behavior  
    - Approach: stabilize network; if already broken, wipe + re-run, don’t waste hours fighting a zombie object
  - **Need local troubleshooting during OOBE**  
    - Use OOBE command prompt (commonly `Shift+F10`) for network validation, logs, and enrollment repair steps  
    - (Keep the actual keystrokes + exact commands in a private/internal version if you prefer)

**2. Compliance triage (phone/laptop “Not compliant”)**
- Triage model:
  1) Is it *actually* stale? (last check-in time, sync status)
  2) Which policy failed? (BitLocker, OS version, Defender, firewall, jailbreak/root, required apps, etc.)
  3) Is it user-fixable vs. requires re-enroll/wipe?
- “Common scenarios” playbooks:
  - **Clock/time drift** → certificates/tokens break → compliance fails  
    - Fix time sync; re-check in; confirm token refresh
  - **Encryption/BitLocker not enabled**  
    - Confirm TPM/secure boot; enforce encryption; validate recovery key escrow
  - **OS version behind**  
    - Force update rings; check storage space; remediate update errors
  - **Mobile compliance**  
    - Confirm Company Portal / MDM profile present
    - Confirm app protection policies + device health attestation (where applicable)

**3. SharePoint library auto-sync to File Explorer (support load killer)**
- Problem:
  - Teams like Accounting constantly need libraries synced, and manual “Sync” support doesn’t scale.
- Pattern:
  - Script identifies SharePoint site + library identifiers (site/list IDs)
  - Intune targets users (group-based assignment) and configures OneDrive to auto-mount the correct libraries
- What matters:
  - Correct ID extraction, correct mapping of “who should get which library”
  - Clean remediation path if OneDrive client is stuck (reset client, clear cache, re-apply policy)

**4. OEM bloatware / stability baseline**
- Practical reality:
  - Manufacturer tools can cause performance + driver + trust issues.
- Pattern:
  - Maintain a small “known removals” list by OEM
  - Remove early in imaging/provisioning
  - Validate performance + Excel/Office behavior + drivers after removal

---

### B) Automation notes* (PowerShell / Graph / CI / operational tooling)

**1. Onboarding automation (pre-HR integration)**
- Inputs captured:
  - first/last, title, office/region, manager
- Output:
  - username/email conventions applied consistently
  - default security groups applied using a **title/region matrix**
- Maturity path (this is what reads as real experience):
  1) Start by **cloning a “known-good” peer** (title/region match)
  2) Move to **standardized default group sets** (stop depending on messy legacy memberships)
  3) Build a GUI for the service desk (create / LOA disable / LOA enable / terminate)

**2. Offboarding / termination automation**
- Objectives:
  - immediate access removal
  - preserve evidence/records
  - delegate access appropriately
  - remove entitlements cleanly
- Practical steps (high value in interviews):
  - disable sign-in, revoke sessions, block access fast
  - mailbox: litigation hold (as required), autoreply to manager, grant mailbox access
  - strip group memberships and privileged roles
  - move to terminated OU, staged deletion timer
  - “approval checkpoint” before final deletion and MFA method cleanup (Graph API)

**3. Day-2 support automation**
- Example patterns:
  - mapped drives not reconnecting → delete + re-map + credential cleanup
  - self-heal scripts for recurring endpoint issues
  - export/validate group membership, license state, mailbox permissions, etc.

**4. CI/CD proof as a portfolio asset**
- Not “I know CI”, but:
  - “Here is a pipeline run, artifacts, and a Jenkins validation screenshot.”

---

### C) Migration notes* (Azure/M365 + cutovers + link repair)

**1. Pre-seed strategy (reduce cutover risk)**
- Copy data early using tools suited to source/target:
  - Migration Manager / SharePoint Migration tools
  - `robocopy` / `AzCopy` for file moves
- Then do periodic delta updates so cutover day is small:
  - “update what changed,” don’t recopy the world
- Cutover approach:
  - freeze change window
  - final delta sync
  - validation (counts, spot checks, integrity checks)
  - communicate rollback plan

**2. Spreadsheet/link repair as a real-world migration pain**
- When file paths change, spreadsheets break.
- Pattern:
  - take old + new paths as parameters
  - scan target file set (NOT live production first)
  - update hyperlinks and relevant formulas without corrupting files
  - handle hidden sheets properly (unhide → update → rehide)
  - preserve last-modified timestamps when needed for audit

---

### D) Cheat sheet* (fast reference)
- RBAC vs sharing vs NTFS/SMB effective permissions
- “Permission pitfalls”:
  - breaking inheritance too deep creates unmanageable sprawl
  - direct user perms vs group-based control
- SharePoint vs file shares:
  - what problems get better
  - what new failure modes appear
- Endpoint quick hits:
  - enrollment sanity checklist
  - troubleshooting order of operations (don’t guess first)

---

## 4) How the content maps to your 9 target titles

### Titles 1–3 (Modern Workplace / Endpoint / Systems Admin)
- Endpoint notes*: Autopilot, compliance triage, OneDrive/SharePoint automation
- Baseline audit: security posture + evidence/reporting

### Titles 4–6 (Cloud / Migration / Solutions Architect)
- Migration notes*: pre-seed/delta strategy, validation, link repair
- Baseline audit: posture checks; can be extended to cloud posture later

### Titles 7–9 (Build/Release / Platform / Automation)
- HelloBuild: CI artifacts + Jenkins proof
- Automation notes*: lifecycle automation (on/offboarding), self-heal scripts, Graph tooling

---

## 5) Sanitization rules (so the portfolio stays safe to publish)
- No tenant IDs, no real site URLs, no user lists, no internal hostnames
- Use placeholders: `<tenant>`, `<domain>`, `<site>`, `<group>`
- Prefer screenshots of *structure* (headings, timestamps, success states), not sensitive payloads
- Any script examples: remove org names, tokens, file shares, and unique identifiers

---

## 6) Short roadmap (next upgrades)
1) Add a structured “Evidence Collector” script (JSON + HTML summary) *(public)*
2) Add an “Autopilot rescue” section with repeatable remediation *(public, sanitized)*
3) Add a “Migration cutover checklist” page *(public)*
4) Add a “Baseline audit vNext” with severity scoring and export formats *(public)*
5) Add a redacted one-page resume PDF link *(optional)*