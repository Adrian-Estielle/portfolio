# Release Runbook (Example)

This is a *template* you can adapt to any organization.

## Goals
- Predictable, repeatable releases
- Minimal human error
- Easy to audit (who/what/when)
- Install/upgrade experience is protected

## Inputs
- Approved change list (tickets/PRs)
- Version target (SemVer + build metadata)
- Target environments (internal QA, customer versions, OS matrix)

## Quality gates
- Build success (clean build from source)
- Unit tests pass
- Static checks (lint/analyzers) pass
- Packaging step produces installer/artifact
- Installer smoke test:
  - clean install
  - upgrade from previous version
  - uninstall
- Signing step (where applicable)
- Release notes prepared

## Artifact handling
- Artifacts stored immutably (hash/fingerprint)
- Retention policy defined
- "Golden" release artifacts tagged and retained longer

## Validation notes (regulated environments)
- Reproduce customer environment as closely as possible (VMs + physical peripherals if needed)
- Capture evidence: logs, configs, versions, steps, expected vs actual
- Make test runs repeatable and reviewable by others

## Roll-forward / Rollback
- Prefer roll-forward fixes when possible (especially for desktop apps)
- If rollback is required, define:
  - what gets reverted
  - who approves
  - how customers are communicated to
  - how to prevent the same regression (postmortem + process change)
