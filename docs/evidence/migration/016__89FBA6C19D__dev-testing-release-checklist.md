# Sanitized artifact (016)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# Development Testing Release Checklist

This runbook prepares the backend, workers, and frontend for a coordinated development testing release. Follow each section in order and record outcomes in `COLLAB_BOARD.md` or the relevant project tracker.

## 1. Prerequisites
- Node.js 22.20.0 with Corepack (`corepack enable && corepack prepare pnpm@10.14.0 --activate`).
- Supabase project (database + auth) with pooled (`DATABASE_URL`) and direct (`DIRECT_URL`) connections enabled.
- Managed Redis instance with TLS (`REDIS_URL` preferred) or host/port/password trio.
- Upstash REST token (optional) and OpenAI, Google Maps, SendGrid API keys.
- Local `.env` copied from `.env.example`; keep actual secrets under `Documents/private-secrets/` per security policy.

## 2. Environment Configuration
1. Populate mandatory secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `DATABASE_URL` (6543 + `?pgbouncer=true`), `DIRECT_URL` (5432), `REDIS_URL` or host/port, `APP_BASE_URL`, `FRONTEND_URL`.
2. Provide AI + messaging keys: `OPENAI_API_KEY`, `GOOGLE_MAPS_KEY`, `SENDGRID_API_KEY`, `EMAIL_FROM`.
3. Update outbound allowlist: include Supabase, Redis REST, OpenAI, SendGrid, Google Maps, and any additional integrations.
4. Run `pnpm env:check` and resolve all missing entries before advancing. (Current blockers: database + Supabase + Redis secrets.)
5. Optional: export sanitized `.<REDACTED_INTERNAL_DOMAIN>` for frontend Vite (`VITE_API_URL`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, `VITE_GOOGLE_MAPS_API_KEY`).

## 3. Database Prep
1. Install dependencies: `pnpm install --frozen-lockfile`.
2. Apply schema changes: `pnpm prisma:migrate` followed by `pnpm prisma:generate`.
3. Verify new tables in Supabase: `ConsentPreference`, `ConsentHistory`, `UserEvent`, `PersonaSnapshot`, `Inquiry`, `ResearchNote`, `ResearchTask`, `ResearchArtifact`, `Insight`, `RoundtableArtifact`.
4. (Optional) Seed baseline data: `pnpm db:seed` (set `SEED_SUPABASE_USER_ID` to link a Supabase user profile).
5. Confirm migrations appear in Supabase dashboard and `migration_lock.toml` matches latest timestamp.

## 4. Services & Workers
1. Start API: `pnpm start` (port 3000) and confirm `/health` returns `{"ok": true}`.
2. Location ingestion worker: `pnpm run worker:location`; verify it drains `Location` rows into `LocationCluster` with ghost-mode respect.
3. AI workers (Redis required):
   - `pnpm ai:worker:roundtable`
   - `pnpm ai:worker:research`
   - `pnpm ai:worker:batch`
   - `pnpm ai:worker:insight`
   - Optional helpers: `pnpm ai:worker:persona`, `pnpm ai:worker:digest`, or `pnpm ai:worker:all`
4. For local multi-process bring-up, `scripts/start-all.sh` launches API + AI workers with file-based logs under `/tmp`.
5. Ensure Redis queues exist (`ai-roundtable`, `ai-research`) and BullMQ dashboards show workers connected.

## 5. Feature Verification
- **Auth & Profiles**: Sign in via Supabase, ensure `ensureProfile` runs, and `Profile.aiConsent / ghostMode` align with consent toggles.
- **Consent**: Hit `/consent` GET/PUT and `/consent/history`; confirm audit rows write to `ConsentHistory` and `UserEvent` (`consent.updated`).
- **Events**: `/events?limit=50` returns recent `UserEvent` rows for the signed-in user.
- **Location Pipeline**: POST `/location/record`, enqueue analysis (`pnpm enqueue:location-analysis`), confirm clusters + matches appear and respect ghost mode.
- **Matches API**: `/matches` returns shared clusters/interests plus AI suggestion metadata when enabled.
- **Research Inquiries**: POST `/inquiries` with topics, ensure planner creates `ResearchNote` + `ResearchTask`, watcher batches to OpenAI, artifacts persist, and insights write to `/insights`.
- **Roundtable**: `pnpm ai:enqueue -- "Prompt"` or POST `/ai/roundtable`; check artifacts stored in `RoundtableArtifact` and SSE stream at `/ai/roundtable/:promptId/stream`.
- **Planning mode**: POST `/ai/roundtable/plan`; validate plan summary, Socket.IO broadcasts (`rt:<promptId>` room), and persistence.
- **JPlan**: Exercise `/jplan` routes to ensure plans update and history tracks iterations.
- **Frontend QA**: Run `pnpm --filter frontend dev`, sign in, load map + matches page, dev console pages under `/dev`, and verify new consent + diary flows.

## 6. Observability & Guardrails
- Confirm egress guard allowlist logs no unexpected blocks once secrets are configured.
- Decide on OpenTelemetry posture: set `OTEL_ENABLED=1` + `OTEL_EXPORTER_OTLP_ENDPOINT` for tracing or leave disabled for this release.
- Review worker logs for retries or dead-letter queues; ensure `scoreRisks` and validator outputs are persisted with roundtable artifacts.

## 7. Acceptance & Hand-off
1. Capture evidence (screenshots, curl outputs, DB rows) for each verification bullet.
2. Update `COLLAB_BOARD.md` and `Documents/Project Progress/Current/razzberry.yml` status entries with outcomes.
3. Document any deviations or blockers—especially secrets rotation, static hosting, or monitoring gaps—in `2025-10-02-open-todos.md` or follow-up issues.
4. Once stable, hand the checklist plus sanitized `.env` to QA stakeholders and schedule the development testing session.

## Known Gaps To Resolve
- Static frontend hosting (Vercel) still pending; ensure host origins are reflected in `CORS_ORIGIN` and Supabase auth settings.
- Secrets currently absent from repo (`pnpm env:check` fails); fetch from secure storage before formal testing.
- Monitoring stack (OTLP endpoint, alerting on batch failures) not yet provisioned—track as part of post-release hardening.
- Map posts tab still uses mock content; replace or hide prior to wider testing if live data not ready.


