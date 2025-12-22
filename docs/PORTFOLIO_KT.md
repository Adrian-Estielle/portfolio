# Portfolio Knowledge Transfer (KT)

This repo is proof-first. The goal is to show repeatable execution via artifacts, runbooks, and working automation.

## Strategy
1) Projects = evidence (code + reproducible process + observable output)
2) Field Notes / KB = credibility
   - Each entry: why → steps → validation → failure modes
   - Include click-paths and log locations (that’s what reads as real work)
3) Sanitization
   - No tenant IDs, secrets, internal hostnames, customer names, or proprietary screenshots.

## Structure
- docs/notes.html = KB hub (lists KB pages)
- docs/kb/ = individual runbook pages

## What’s new in this update
- Workday provisioning runbooks (cloud + hybrid to AD)
- AD replication preflight for provisioning projects
- Workday XPath cheat sheet (mapping gotchas)