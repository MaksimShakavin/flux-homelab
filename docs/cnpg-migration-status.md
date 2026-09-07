# CNPG migration status tracker

Tracks the Crunchy PGO → CloudNative-PG migration of the 9 component-based Postgres apps.
Procedure: `scripts/cnpg-migrate-agent-prompt.md`. Runbook: `docs/cnpg-migration-runbook.md`.

**immich is OUT OF SCOPE** (stays on Crunchy for its VectorChord work; Crunchy operator + MinIO `postgress` bucket stay).

## Stage legend
- **S1** — stand up empty CNPG alongside Crunchy (commit)
- **S2** — move the data (`scripts/cnpg-migrate-data.sh`, no commit, needs `VERIFY OK`)
- **S3** — repoint app to CNPG, Crunchy still fallback (commit)
- **S4** — retire Crunchy for this app (commit)

## Progress

| Order | App | ns | S1 | S2 | S3 | S4 | Notes |
|---|---|---|----|----|----|----|-------|
| — | prowlarr | default | ✅ | ✅ | ✅ | ✅ | Reference run (pre-existing) |
| 1 | radarr | default | ✅ | ✅ | ✅ | ✅ | **Done.** Had crunchy dep+health block (runbook said none) — removed in S4 |
| 2 | sonarr | default | ✅ | ✅ | ✅ | ✅ | **Done.** Had crunchy dep+health block (runbook said none) — removed in S4 |
| 3 | mealie | default | ⬜ | ⬜ | ⬜ | ⬜ | crunchy dep+health; KOPIUR 3Gi |
| 4 | paperless | default | ⬜ | ⬜ | ⬜ | ⬜ | crunchy dep+health; dragonfly + zeroscaler (keep) |
| 5 | lubelogger | default | ⬜ | ⬜ | ⬜ | ⬜ | SecretStore/ES rewire; KOPIUR 2Gi, GATUS |
| 6 | ghostfolio | default | ⬜ | ⬜ | ⬜ | ⬜ | crunchy dep+health; dragonfly (keep); no kopiur |
| 7 | securo | default | ⬜ | ⬜ | ⬜ | ⬜ | pgvector postInitSQL; dragonfly; KOPIUR 5Gi |
| 8 | authentik | security | ⬜ | ⬜ | ⬜ | ⬜ | ns=security; server+worker; POOL_MODE; SSO — do last |
| — | immich | default | 🚫 | 🚫 | 🚫 | 🚫 | OUT OF SCOPE |

Legend: ⬜ pending · 🔄 in progress · ✅ done · ❌ failed/blocked · 🚫 out of scope

## Log

_(newest first)_

### sonarr — ✅ complete (2026-09-07)
- S1: `postgres-sonarr` Ready 3/3, `postgres-sonarr-app` secret mirrored to default, app stayed on Crunchy.
  Initial hiccup: 3rd replica stuck `Pending` — control-2 was at 99% memory *requests* (only ~15Mi free of
  ~28.5Gi allocatable, though only 51% actually used) and CNPG's hard pod anti-affinity forced it onto that
  node. Not a config error; user trimmed over-provisioned app requests → replica scheduled → Ready 3/3.
- S2: `cnpg-migrate-data.sh sonarr default` → **VERIFY OK**, 39/39 tables identical. Same benign
  `pg_stat_statements`/`pgaudit` "must be superuser" noise as radarr (Crunchy extensions sonarr doesn't use).
- S3: pod Ready 1/1, 0 restarts, host env `postgres-sonarr-rw.database.svc`, logs show **Postgres 17.11** +
  migrations ran; `/ping` → HTTP 200.
- S4: on-demand backup `postgres-sonarr-cutover` → **completed `s3://cnpg/sonarr`**. Crunchy
  `PostgresCluster/sonarr` + pgbouncer/pguser secrets/pods/pvc pruned; app healthy, `/ping` 200.
- **Divergence:** runbook said sonarr has "no crunchy dep block" but its `ks.yaml` DID have a
  `crunchy-postgres-operator` dependsOn + `PostgresCluster` ProxyAvailable healthCheck (same as radarr).
  Removed both in S4. Note: sonarr had NO `longhorn` dependsOn (unlike radarr), so the entire `dependsOn`
  block was removed. **Check mealie/paperless/ghostfolio for the same discrepancy.**

### radarr — ✅ complete (2026-09-07)
- S1: `postgres-radarr` Ready 3/3, `postgres-radarr-app` secret mirrored to default, app stayed on Crunchy.
- S2: `cnpg-migrate-data.sh radarr default` → **VERIFY OK**, 42/42 tables identical. Noise: harmless
  `pg_stat_statements`/`pgaudit` "must be superuser" errors (Crunchy extensions radarr doesn't use), not
  the documented `_crunchypgbouncer` ones — same benign category.
- S3: pod Ready 1/1, 0 restarts, logs show `Host=postgres-radarr-rw.database.svc` + **Postgres 17.11** +
  migrations ran; `/ping` → HTTP 200.
- S4: on-demand backup `postgres-radarr-cutover` → **completed `s3://cnpg/radarr`** (barman upload ~7min).
  Crunchy `PostgresCluster/radarr` + pods/pvc/secrets pruned; app healthy.
- **Divergence:** runbook table said radarr has "no crunchy dep/health block" but its `ks.yaml` DID have a
  `crunchy-postgres-operator` dependsOn + `PostgresCluster` ProxyAvailable healthCheck. Removed both in S4
  (kept the `longhorn` dependsOn). **Check sonarr for the same discrepancy.**

## After all 8 remaining apps
- Remove `components/postgress` from the tree (grep-confirm no non-immich refs).
- **Keep** Crunchy operator + MinIO `postgress` bucket (immich still needs them).
- Optional: clean up throwaway Garage `s3://cnpg/testpg` objects from Phase A.
