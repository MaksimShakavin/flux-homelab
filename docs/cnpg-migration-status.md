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
| 2 | sonarr | default | ⬜ | ⬜ | ⬜ | ⬜ | zeroscaler; no crunchy dep block |
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
