# Dispatch: migrate the NEXT app (Crunchy → CNPG)

Continue the Crunchy PGO → CloudNative-PG migration. **prowlarr and radarr are fully migrated.**
Do exactly ONE app: the next ⬜ row in `docs/cnpg-migration-status.md`. Right now that is **sonarr**
(`APP_NAMESPACE: default`). Order: sonarr → mealie → paperless → lubelogger → ghostfolio → securo → authentik.

## Read first (in this order)
1. `docs/cnpg-migration-status.md` — the live tracker + per-app log. Confirm which app is next; read radarr's log entry.
2. `scripts/cnpg-migrate-agent-prompt.md` — the full 4-stage procedure + guardrails. Follow it exactly.
3. `docs/cnpg-migration-runbook.md` — the per-app table row for YOUR app (exact HR wiring, components to keep,
   dragonfly/zeroscaler deps, securo pgvector, authentik two-workload/ns=security specifics).
4. Reference the two completed apps as concrete templates: `kubernetes/apps/default/prowlarr/` and
   `kubernetes/apps/default/radarr/` (db/postgres/ layout, ks.yaml components, app/helmrelease.yaml DB block).

## Environment
- Repo root is cwd. `export KUBECONFIG=$PWD/kubeconfig` for all kubectl/flux.
- Commit style: one-line conventional commits, NO body, NO Co-Authored-By. Push to `main` directly, then
  `flux reconcile ...` — nothing applies until pushed.

## Hard rules (learned the hard way on radarr)
- **Another agent shares this repo. NEVER `git add -A` / `git add .` / `git commit -a`.** Stage only the
  explicit files you created/edited (`git add <path> ...`), and run `git status --short` before each commit
  to confirm every staged path is yours.
- **The runbook's per-app notes can be wrong about the crunchy dep/health block.** radarr was listed as
  "no crunchy dep block" but its `ks.yaml` actually had a `crunchy-postgres-operator` dependsOn + a
  `PostgresCluster` ProxyAvailable `healthCheckExprs`. **Always read the app's real `ks.yaml`** and, in
  Stage 4, remove whatever crunchy `dependsOn`/`healthCheckExprs`/`POOL_MODE` actually exists (keep the
  `longhorn` dependsOn). sonarr is "same as radarr" per the runbook — so expect this block on sonarr too.
- Golden rule: never cut over in one commit. Crunchy stays a hot fallback until Stage 3 verifies. If any
  stage's verification fails, STOP and report — do not remove `components/postgress` before Stage 4.
- Touch ONLY this app's files + the parent `kustomization.yaml`. Don't modify `components/postgres`, the
  operator, other apps, or immich (out of scope).

## When done
Update `docs/cnpg-migration-status.md`: flip the app's S1–S4 cells to ✅, add a dated log entry (VERIFY OK
result, Stage-3 healthcheck, Garage backup path `s3://cnpg/<app>`, confirmation Crunchy pruned, any
divergence from the runbook). Commit that doc change on its own. Then stop — one app per dispatch.
