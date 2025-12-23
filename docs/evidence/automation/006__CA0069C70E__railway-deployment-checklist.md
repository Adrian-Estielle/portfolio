# Sanitized artifact (006)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
# Railway Deployment Checklist (API + Workers)

Use this when backend updates are ready but `railway up` keeps timing out or tokens have expired. It captures the playbook the support agents have been following during the current blitz.

## 1. Authenticate via deployment token
1. In Railway → Project → Settings → Deployment Tokens, create a token scoped to the Production environment.
2. Export it before running commands:
   ```bash
   export RAILWAY_TOKEN=rwlt_...
   ```
3. Confirm auth works:
   ```bash
   railway whoami
   ```
   You should see the service account instead of “Unauthorized”.

> Skip `railway login --browserless` inside Codex; it fails without a browser. Always use deployment tokens when running from automations.

## 2. Deploy the API service
```bash
railway up --service razzberry --ci
```
- `--ci` skips interactive prompts and streams build logs.
- If the upload stalls, retry once after ~30 seconds. Persistent `operation timed out` errors usually mean Backboard is unhealthy; check Railway status before retrying.

## 3. Check deployment state
```bash
railway status --service razzberry
railway logs --service razzberry --lines 200
```
- Ensure the latest deployment shows `SUCCEEDED`.
- Look for Prisma errors or missing env vars in the logs before moving on.

## 4. Run post-deploy health checks
```bash
railway run --service razzberry pnpm run health:url
```
- Alternatively hit `https://<service-domain>/health` manually.
- If `/health` is OK but the worker queues lag, run `pnpm run health:postdeploy` which also checks Redis and Supabase connectivity.

## 5. Workers
- Location queue service:
  ```bash
  railway up --service razzberry-worker --ci
  railway logs --service razzberry-worker --lines 200
  ```
  Ensure `REDIS_URL`, `SUPABASE_*`, and other required vars are present.
- AI bundle service (Railway `worker-ai`):
  ```bash
  railway up --service worker-ai --ci
  railway logs --service worker-ai --lines 200
  ```
  The service start command is `pnpm ai:worker:all`, which launches the roundtable, persona, daily digest, research planner/batch, and insight workers together. Confirm `REDIS_URL`, `OPENAI_API_KEY`, and any research persona env vars before redeploying.

## 6. Document the deploy
After a successful deploy, update:
- `COLLAB_BOARD.md` with the timestamp + summary (migrations applied, API online).
- `Documents/Project Progress/Current/20251006-network-coordination.txt` with any token rotations or anomalies.

### Troubleshooting Notes
- **Timeouts at Backboard upload:** Pause 5 minutes, then retry with `railway up --service ... --ci`. If it persists, escalate in the team channel—Backboard may be degraded globally.
- **Supabase connection errors (P1001):** Verify `DIRECT_URL` uses the pooler host `aws-1-us-west-1.pooler.supabase.com` and that the IP has access. Use `railway run --service razzberry env` to inspect live values.
- **Missing migrations:** Run `pnpm prisma migrate deploy && pnpm prisma generate` locally (with DB access) before redeploying so schema and client stay aligned.

Keep this checklist close while coordinating with the support GPTs; it keeps the handoffs consistent.

