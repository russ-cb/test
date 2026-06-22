## PR #1433 Review — feat: production onboarding for Resilience Hub at resilience-hub.uk (RHUB-27)

Overall: Looks good. Well-structured production standup following the same patterns as jpmcv2, kiosk, and yodha. The multi-zone redirect 
strategy is clean and the RDS Proxy integration is a nice improvement over direct cluster connections.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


### ✅ Positives

- **Terraform module** — identical signature to stage and other prod apps (environment, oidc_provider_arn, cache_user_group_id). Module 
has proper outputs (db_proxy_auth_secret_arn) consumed by the proxy config.
- **RDS Proxy** — connecting through the proxy rather than direct to Aurora is better than the jpmcv2/flubooking pattern. Connection 
pooling, IAM auth on the proxy side, and the extra_user_secret_arns wiring is correct.
- **DNS architecture** — three zones, cleanly separated:
  - resiliencehub.uk — canonical (ALB DNS + www→apex redirect)
  - resilience-hub.uk — 301 redirect to canonical
  - resilience-hub.co.uk — 301 redirect to canonical
  - All preserve path + query string. ✅
- **Zone IDs resolved via data source** — data.cloudflare_zone lookup by name instead of hardcoding. Better than the legacy pattern used 
for other zones.
- **ALB priority 500** — no collision on the prod HTTPS listener (existing: 100, 200, 300, 400).
- **ArgoCD manifest** — standard pattern, automated sync, prune + self-heal.
- **HPA 2–10, on-demand** — sensible prod defaults.
- **Sessions on Redis, cache/queue on Postgres** — interesting split. Sessions need fast cross-pod access (correct for HPA + Octane), 
while cache/queue using Postgres via the proxy avoids Valkey as a single dependency for data integrity.
- **Reversible / incremental** — 4 well-scoped commits, each addressing a specific concern (standup → zone ID fix → canonical host fix → 
formatting).

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


### ⚠️ Observations / Items to Verify

1. resiliencehub.uk zone — no dns.tf — The redirect-only zones (resilience-hub.uk, resilience-hub.co.uk) both have a dns.tf with CNAME 
records pointing to the canonical. But the canonical zone (resiliencehub.uk) has no dns.tf — its DNS records live in 
environments/aws/core/ingress.tf instead. This is intentional (those records depend on module.ingress.prod_alb_dns_name) and the 
stack.tm.hcl has after = ["/environments/aws/core"], so the dependency order is correct. However, having the records split between two 
Terraform stacks (core manages the A/CNAME, the Cloudflare zone manages the redirect ruleset) is slightly unusual. Worth a comment in the
zone's directory noting that DNS records are managed in core. Not a blocker.

2. OCTANE_WORKERS: "8" (prod) vs stage — Did stage validate this value, or does stage use a different count? The comment says "8 fits the 
1.5Gi app memory limit" — worth confirming the chart's default resource limits are actually 1.5Gi (I don't see resource requests/limits 
in the values file).

3. DB_SEARCH_PATH: "rhub" — no public on the path — jpmcv2 uses "jpmcv2,public" to resolve extensions (btree_gist). If Resilience Hub uses
any extensions installed in public (e.g. uuid-ossp, pgcrypto), they won't resolve without public on the path. Confirm the app doesn't 
depend on public-schema extensions, or add public to the path.

4. Secret placeholder CHANGE_ME_VIA_CONSOLE — The db_proxy_auth secret is created with a placeholder. The ignore_changes lifecycle is 
correct (operator sets real value out of band). Just ensure the runbook/deployment steps explicitly call out populating this before the 
proxy tries to use it — a proxy auth failure would prevent all DB connections.

5. No DB_SSLMODE — The jpmcv2 prod values include DB_SSLMODE: "require". This PR doesn't set it. The app may default to prefer or require 
depending on the Laravel/PHP PgSQL driver defaults. Worth explicitly setting DB_SSLMODE: "require" for defense-in-depth (traffic goes 
through the RDS Proxy, but the proxy→Aurora hop should also be encrypted).

6. MAIL_MAILER: "log" — Correct per the comment (admin configures SendGrid at runtime via DB settings). Just noting that until an admin 
configures it, no emails will actually be sent (they'll go to stderr). Fine for initial deploy.

7. resiliencehub.uk Cloudflare zone — stack.tm.hcl says after = ["/environments/aws/core"] — This means the Cloudflare redirect ruleset 
depends on core being applied first. But core itself now depends on data.cloudflare_zone.resiliencehub_uk to resolve the zone ID. This is
fine because the zone already exists in Cloudflare (data source reads it); only the ruleset is new. But on a fresh account bootstrap this 
would be a chicken-and-egg — acceptable for a non-greenfield repo like this.

8. ALB certificate SAN includes www.resiliencehub.uk — The comment says "for safety in case the edge redirect is ever disabled". Good 
defensive practice. ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


### Summary

| Pre-deploy gate | Status |
|---|---|
| Terraform module exists with correct interface | ✅ |
| ALB priority unique (500) | ✅ |
| ACM cert + SNI on prod listener | ✅ |
| Cloudflare zones exist (data source will resolve) | ❓ Verify zones are active |
| Prod secrets populated (/prod/eks/rhub/secrets, cache password, proxy auth) | ❓ Verify before apply |
| Prod DB role + rhub schema created on Aurora | ❓ Verify |
| DB_SEARCH_PATH doesn't need public | ❓ Confirm |
| DB_SSLMODE explicitly set | ⚠️ Recommend adding |
| Resource limits defined in chart defaults | ❓ Confirm 1.5Gi |

Verdict: Approve with the minor suggestions above (DB_SSLMODE, DB_SEARCH_PATH confirmation). The architecture is sound and follows 
established repo patterns.
