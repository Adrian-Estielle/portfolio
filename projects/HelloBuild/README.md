# HelloBuild — CI/CD Portfolio Reference

This repo is intentionally simple, but "real":

- ✅ **Jenkins** pipeline (`Jenkinsfile`)
- ✅ **GitHub Actions** pipeline (`.github/workflows/ci.yml`)
- ✅ Build → test → package → archive artifacts
- ✅ Build metadata captured for traceability

## What to say in an interview

> "I built a small reference repo that demonstrates how I structure build/test/package pipelines with artifact traceability. The same patterns scale to Windows desktop builds, installers, signing, versioning, and release runbooks."

## Run locally

### Prereqs
- .NET 8 SDK
- Git
- (Optional) Docker Desktop if you want to run Jenkins locally

### Build/test/package
```powershell
pwsh -File .\scripts\build.ps1
```

Artifacts land in `.\artifacts\`.

## Jenkins (local)

Start Jenkins using Docker:

```powershell
pwsh -File .\scripts\jenkins_bootstrap.ps1
```

Then:
1. Open `http://localhost:8080`
2. Get the initial admin password:
   ```powershell
   docker exec jenkins-lts cat /var/jenkins_home/secrets/initialAdminPassword
   ```
3. Create a Pipeline job that points to this repo and uses `Jenkinsfile`

## Extending toward a Windows desktop build/release role

If you want to push this further:
- Add code signing (even self-signed for the demo)
- Add version stamping based on git tags + build number
- Add MSI/MSIX packaging (WiX or MSIX Packaging Tool)
- Add release notes generation + GitHub Releases publishing
- Add a release runbook and quality gates (installer smoke tests, update tests, rollback/forward plan)

See `docs/Release_Runbook.md`.
