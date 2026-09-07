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
| 1 | radarr | default | ⬜ | ⬜ | ⬜ | ⬜ | zeroscaler; no crunchy dep block |
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

### radarr — starting
- Stage 1 in progress.

## After all 8 remaining apps
- Remove `components/postgress` from the tree (grep-confirm no non-immich refs).
- **Keep** Crunchy operator + MinIO `postgress` bucket (immich still needs them).
- Optional: clean up throwaway Garage `s3://cnpg/testpg` objects from Phase A.
