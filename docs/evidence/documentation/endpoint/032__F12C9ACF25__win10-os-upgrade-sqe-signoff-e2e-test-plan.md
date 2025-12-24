# Windows 10 OS upgrade package — SQE sign-off (E2E test plan, sanitized)

## Context
I used this document to drive an end-to-end SQE validation cycle for a Windows 10 in-place upgrade package deployed to Windows-based medication dispensing endpoints (virtual and physical). The goal was to prove upgrade + restore paths were safe across multiple supported application versions and connectivity modes.

## Scope
- Validate two deployment modes: cloud-connected (HTTPS) and on-prem queue-based delivery.
- Verify OS + database upgrade steps complete without breaking core workflows.
- Confirm peripheral and security/OS baselines remain stable after the upgrade.
- Capture sign-off expectations across engineering / product / program roles.

## Test / validation matrix (sanitized summary)
| Target | Connectivity | App/firmware coverage | What was validated |
|---|---|---|---|
| Lab VMs and lab consoles | Cloud-connected (HTTPS) | Multiple supported app versions (representative spread) | Preflight checks, upgrade execution, service health, workflow regression |
| Physical endpoints (“cabinets”) | Queue-based delivery | Multiple supported app versions (representative spread) | Upgrade + post-upgrade peripherals, lock/drawer behavior, restore + post-restore validation |
| Mixed endpoints (final build pass) | Both | Final-build verification set | Repeatability, “no new defects” signal, readiness for release |

## Acceptance criteria
- Upgrade completes successfully on all representative targets without new Sev 1/2 defects.
- Restore/downgrade path returns the device to a functional baseline.
- Core workflows and peripherals remain operational (scan/print/lock inputs, etc.).
- Key OS/security settings remain in the expected state (where applicable).

## Rollback / contingency summary
- Use the documented restore mechanism to return the device to its prior baseline if any acceptance criterion fails.
- After restore, re-run a targeted “post-restore smoke” (services, workflows, and peripherals) before considering the device returned to service.

## Evidence notes (what this demonstrates)
- Release gating via a repeatable validation plan (scope → matrix → execution → sign-off).
- Risk management across multiple deployment paths (cloud vs local delivery).
- Focus on observable outcomes (workflows/peripherals/services) instead of “it installed”.

## Redactions summary
- Replaced: internal names/signatures, internal IPs/hostnames, internal share/URL locations, internal ticket/test-case IDs, and internal tool paths.

