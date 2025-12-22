# Portfolio Knowledge Transfer (KT)

This repo is a proof-first engineering portfolio. The goal is not to claim broad expertise — it’s to show **repeatable execution** via artifacts, runbooks, and working automation.

## Strategy
1) **Projects = evidence**
   - A project should have:
     - code
     - a reproducible process (pipeline / script)
     - an observable output (artifact, report, screenshot, CI run)

2) **Field Notes / KB = credibility**
   - The KB contains sanitized runbooks and “edge case” notes that only show up when you’ve done this in real environments.
   - Format each KB entry as:
     - *Why / goal*
     - *Steps*
     - *Validation*
     - *Failure modes / recovery*
     - *Sanitized references (optional)*

3) **Tone**
   - First-person, practical, and operational.
   - Avoid “AI assistant” phrasing (no “I can help you…”). Write like an engineer documenting real work.

4) **Sanitization rules**
   - No tenant IDs, secrets, internal hostnames, customer names, or proprietary screenshots.
   - Use examples or placeholders where needed.
   - Prefer “patterns” over “company specifics.”

## Site structure (docs/)
- index.html = portfolio home (projects + KB hub)
- 
otes.html = Field Notes / KB hub (runbooks + diagrams)
- 
otes_outline.md = quick-edit outline for planning additions
- eports/ = sample artifacts that are safe to publish
- ssets/ = screenshots used on the site

## What to add next (high ROI)
- Role Evidence Map: map the 9 target titles → (project + KB entries) → proof links.
- Resume PDF link (public-safe copy) + short skills matrix (do NOT publish raw “fact bank”).
- A few additional KB entries:
  - Autopilot “half-enrolled” recovery
  - Intune compliance triage with exact validation checks
  - OneDrive/SharePoint auto-mount at scale (ID mapping strategy)
  - Migration performance validation checklist

## Editing workflow
- Add/update KB content in docs/notes.html
- Keep docs/notes_outline.md aligned so future edits stay consistent
- Commit small, frequent, traceable changes