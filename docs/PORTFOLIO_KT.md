# Portfolio Knowledge Transfer (KT)

This repo is a proof-first engineering portfolio. The goal is simple: **show repeatable execution** (working pipelines, scripts, and artifacts) plus **real-world operational notes** (runbooks and edge cases).

## Strategy
1) **Projects = evidence**
   - Each project should have:
     - code
     - a reproducible process (pipeline / script)
     - an observable output (artifact, report, screenshot, CI run)

2) **Field Notes / KB = credibility**
   - The KB is split into separate pages (not one giant anchor doc):
     - docs/kb/endpoint.html
     - docs/kb/automation.html
     - docs/kb/migration.html
     - docs/kb/cheatsheets.html
     - docs/kb/ci.html
   - Format each runbook entry:
     - Why / goal
     - Steps
     - Validation
     - Failure modes + recovery
     - Sanitized references where useful

3) **Evidence archive**
   - Sanitized historical material lives here:
     - docs/evidence/scripts.html (files under docs/evidence/scripts/)
     - docs/evidence/documentation.html (files under docs/evidence/docs/)
   - Keep artifacts practical and redacted.

4) **Tone**
   - First-person, operational, practical.
   - Avoid assistant/AI phrasing. Write like an engineer documenting real work.

## Sanitization rules (non-negotiable)
- No tenant IDs, secrets, internal hostnames, customer names, or proprietary screenshots.
- Prefer patterns + placeholders over company specifics.
- Logs are great — redact identifiers.

## Editing workflow
- Update KB pages in docs/kb/
- Add sanitized scripts/docs under docs/evidence/
- Commit small, traceable changes