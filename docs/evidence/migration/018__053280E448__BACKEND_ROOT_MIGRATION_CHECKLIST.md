# Sanitized artifact (018)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# Backend Root Migration Checklist

Primary goal
- Flatten backend to repo root so all runtime, build, and deploy paths reference root assets (`index.js`, `prisma/`, `routes/`, `services/`, `worker/`).

Acceptance criteria
- CI green: schema validate and entrypoint syntax check from root.
- Railway deploys: API runs, migrations apply, health passes; Worker starts from root and connects to Redis.
- No remaining critical configs require `cd backend` or path prefixes to `backend/`.

Build & Deploy
- [x] Nixpacks (API):
  - Files: `nixpacks.toml`
  - Replace `cd backend` steps with root commands:
    - install: `corepack enable && corepack prepare pnpm@10.14.0 --activate && pnpm install`
    - build: `pnpm prisma:generate`
    - start: `pnpm start`
  - Or archive Nixpacks if Dockerfile is the single source of truth for API.
- [x] Nixpacks (Worker):
  - Files: `nixpacks.worker.toml`
  - Replace `cd backend` steps with root equivalents or point start to `pnpm run worker:location`.
  - Align Prisma generate/migrate to use `./prisma/schema.prisma`.
- [x] Railway worker config:
  - File: `worker.railway.json`
  - Update `startCommand` to: `pnpm prisma:migrate && node worker/locationWorker.js` (or `pnpm run worker:location`).

CI/CD
- [x] GitHub Actions (CI checks):
  - File: `.github/workflows/ci-checks.yml`
  - Update Prisma validate path: `--schema=prisma/schema.prisma`
  - Update entrypoint check: `node --check index.js`
- [x] CODEOWNERS (optional):
  - File: `.github/CODEOWNERS`
  - Adjust patterns if we remove `backend/` folder entirely or migrate ownership to root paths.

Runtime & Scripts
- [x] Scripts referencing `cd backend`:
  - Files: `scripts/railway-migrate.sh`, `fix-deployment.sh`
  - Update to root prisma commands: `npx prisma generate --schema=./prisma/schema.prisma`, `npx prisma migrate deploy --schema=./prisma/schema.prisma`.
- [x] Verify `docker-entrypoint.sh` behavior:
  - It already runs from script directory at root and uses root `prisma/schema.prisma`. Comments mention “backend”; update comment when convenient.

Documentation
- [x] README updates:
  - Replace workspace‑scoped commands (`--filter ./backend...`) with root equivalents.
  - Clarify how to run API (`pnpm start`) and Worker (`pnpm run worker:location`).
- [x] Docs under `docs/` and `Documents/` that claim “API resides in backend/”:
  - Update or annotate with a short “flattened root (v5)” note.

Cleanup
- [x] `backend/` folder:
  - Directory removed on 2025-10-02; historical docs remain under `Documents/`.

Sanity validation
- [x] `pnpm install --frozen-lockfile` succeeds. (2025-10-02)
- [x] `pnpm prisma:generate` from root succeeds, client resolves. (2025-10-02)
- [x] API boots locally (`pnpm start`), health at `/health` returns ok. (2025-10-02: ran `node -r dotenv/config index.js`, verified `{"ok":true}` on `/health` with live Supabase/Redis env.)
- [x] Worker boots (`pnpm run worker:location`), connects to Redis, no unhandled errors. (2025-10-02: ran `node worker/locationWorker.js` against Upstash; enqueued analysis job, no errors logged.)
- [x] CI passes on PR: schema validate + node check updated to root. (2025-10-02: ran frontend build, `pnpm exec prisma validate`, and `node --check index.js` locally to mirror workflow steps.)

Notes
- See `.collab/findings/backend-path-audit.txt` (currently empty) for the latest scan.
- Rebuild findings with `bash scripts/audit_backend_refs.sh`.

