# Sanitized artifact (002)
# Notes: identifiers/secrets replaced with <REDACTED_*> placeholders.
# Source: <REDACTED_PATH>
<#
  Generates docs/concept-primer.md containing the same content
  that used to live in the “Concept Primer – OAuth & RLS” PDF.
#>
@'
# Concept Primer – OAuth 2, PKCE & PostgreSQL RLS

## Why OAuth 2 / OpenID Connect is more than “Login with Google”
*   Redirect / state / code‑exchange dance
*   Mobile apps must use **PKCE** (no client secret)
*   Short‑lived JWT access tokens + long‑lived refresh tokens
*   Rotation & revocation on device loss

## Why Row‑Level Security (RLS) matters
*   Policies are enforced **inside** PostgreSQL
*   Every micro‑service, BI tool, ad‑hoc query is automatically safe
*   Engine reads `current_setting('jwt.claims.sub')` to know caller

## Dependency graph (high‑level)

(OAuth provider) ─► JWT ─► Express middleware `requireAuth`
                 │
                 ▼
          `SET jwt.claims.sub` ─► RLS policies
                 │
                 ▼
      Safe SQL from Prisma / Worker / BI
'@ | Set-Content -Encoding utf8 -Path (Join-Path (git rev-parse --show-toplevel).Trim() 'docs/concept-primer.md')

Write-Host "✅  Wrote docs/concept-primer.md – convert to PDF if needed"

