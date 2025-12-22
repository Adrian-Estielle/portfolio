# Portfolio Knowledge Transfer (KT)

This repo is a proof-first engineering portfolio. The goal is to show repeatable execution via artifacts, runbooks, and working automation.

## Strategy
1) Projects = evidence
   - code + reproducible process + observable output (artifact/report/screenshot)

2) Field Notes / KB = credibility
   - Each KB entry follows: why → steps → validation → failure modes
   - Notes are sanitized (no tenant IDs, secrets, internal hostnames, customer identifiers)

3) Structure
   - docs/notes.html = KB hub (links to separate pages)
   - docs/kb/ = individual runbook pages (no mega anchor dumps)
   - docs/archives.html + docs/archive/ = supporting sanitized scripts/logs/templates
   - docs/_drafts/ = hidden WIP

4) Tone
   - First-person, operational. No “AI assistant” phrasing.

## Editing workflow
- Add runbooks as new docs/kb/*.html
- Keep docs/notes_outline.md aligned
- Publish evidence to docs/archive/* and link from KB pages
- Commit small, traceable changes