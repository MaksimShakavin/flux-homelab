# Crunchy PGO → CloudNative-PG per-app migration runbook

Migrates the 9 component-based Postgres apps from **Crunchy PGO** (`components/postgress`, pgBackRest→MinIO,
pgBouncer) to **CloudNative-PG** (`components/postgres`, barman→Garage, direct connections), using the
per-app-db pattern (`docs/per-app-db-pattern.md`).

- **immich is OUT OF SCOPE** — it stays on Crunchy (rolls its own inline pgvecto.rs cluster) and migrates
  later with its VectorChord work. The Crunchy operator + MinIO `postgress` bucket therefore STAY until then.
- Phase A (operator + `components/postgres` + Garage `cnpg` bucket) is **already done and verified**.
- **prowlarr is already fully migrated** (the reference run). Remaining: radarr, sonarr, mealie, paperless,
  lubelogger, ghostfolio, securo, authentik.

## Golden rule

**Never cut over in one commit.** Crunchy stays a hot, untouched fallback (we only *read* it via `pg_dump`)
until the app is proven on CNPG. A bad cutover is then a one-commit revert to an intact Crunchy DB.

## Naming (all CNPG resources grouped under `postgres-<app>`)

| Thing | Value |
|---|---|
| CNPG Cluster | `postgres-<app>` (namespace `database`) |
| RW service (app connects here) | `postgres-<app>-rw.database.svc` |
| App creds secret (operator-gen, mirrored to app ns) | `postgres-<app>-app` |
| Barman S3 creds secret | `postgres-<app>-backup` |
| Garage backup path | `s3://cnpg/<app>` |
| Flux Kustomization (cluster) | `<app>-postgres` (object lives in app ns) |
| Crunchy source (dump from) | `<app>-primary.<ns>.svc`, secret `<app>-pguser-<app>` |

CNPG's `postgres-<app>-app` secret carries BOTH `user` and `username` keys (identical) plus
`password`/`dbname`/`port`; the mirror ExternalSecret rewrites `host`/`uri`/`jdbc-uri` to the FQDN.

## Per-app stages

### Stage 1 — stand up empty CNPG alongside Crunchy (commit)
Files per app (Option A layout — mirror rides the app's existing Kustomization):

1. `kubernetes/apps/<ns>/<app>/db/postgres/ks.yaml` — Flux Kustomization `<app>-postgres`:
   - `components: [ ../../../../../../components/postgres ]`
   - `dependsOn`: `cloudnative-pg`/`database` + `onepassword`/`external-secrets`
   - `healthCheckExprs` on `postgresql.cnpg.io/v1` `Cluster` Ready condition
   - `path: ./kubernetes/apps/<ns>/<app>/db/postgres/app`, `targetNamespace: database`, `wait: true`
   - `postBuild.substitute`: `APP`, `APP_NAMESPACE`, + `POSTGRES_SIZE`/`POSTGRES_IMAGE` overrides as needed
2. `kubernetes/apps/<ns>/<app>/db/postgres/app/kustomization.yaml` — `resources: []` (component supplies all)
3. Edit `<app>/ks.yaml`: ADD `../../../../components/postgres/credentials-mirror` to `components`,
   **KEEP** `../../../../components/postgress`, add `APP_NAMESPACE` to `substitute`.
4. Register `./<app>/db/postgres/ks.yaml` in `kubernetes/apps/<ns>/kustomization.yaml`.

Commit, push, `flux reconcile kustomization cluster-apps --with-source`. Wait for:
- `kubectl get cluster.postgresql.cnpg.io -n database postgres-<app>` → Ready 3/3
- `kubectl get secret -n <ns> postgres-<app>-app` present
- App still Running on Crunchy (unchanged). `flux reconcile kustomization <app>-postgres -n <ns>` if the
  ks went `False` on the transient bootstrap `Failed` phase (it self-heals once Ready).

### Stage 2 — move the data (live, no commit)
```sh
KUBECONFIG=./kubeconfig scripts/cnpg-migrate-data.sh <app> [<ns>]   # ns defaults to "default"
```
The script scales the app to 0, dumps from the Crunchy **primary** (never pgbouncer), restores into CNPG,
and prints an exact source-vs-target row-count diff. **Expected harmless noise**: ~6
`role "_crunchypgbouncer" does not exist` ACL errors (Crunchy's pgbouncer schema) — the script filters them.
Confirm it prints `VERIFY OK`.

### Stage 3 — repoint the app to CNPG (commit; Crunchy still fallback)
Edit the app's `helmrelease.yaml` DB wiring (see per-app table below): host → `postgres-<app>-rw.database.svc`,
password/URI secret → `postgres-<app>-app`. **Leave `components/postgress` in place.** Commit, push, then:
```sh
flux reconcile kustomization <app> -n <ns> --with-source
flux reconcile helmrelease <app> -n <ns>       # restores replicas (we scaled to 0) + new env
```
Verify: pod Ready, logs show it connected (PG 17.11) & ran migrations, app healthcheck passes, 0 restarts.
**Rollback = revert this one commit** → app returns to Crunchy (still holding all data).

### Stage 4 — retire Crunchy for this app (commit, only after verify)
1. Trigger an on-demand CNPG backup and confirm it lands in Garage:
   ```sh
   kubectl apply -f - <<EOF
   apiVersion: postgresql.cnpg.io/v1
   kind: Backup
   metadata: { name: postgres-<app>-cutover, namespace: database }
   spec: { method: barmanObjectStore, cluster: { name: postgres-<app> } }
   EOF
   kubectl get backups.postgresql.cnpg.io -n database postgres-<app>-cutover -o jsonpath='{.status.phase} {.status.destinationPath}'
   ```
   (`backup` short-name resolves to Longhorn — always use `backups.postgresql.cnpg.io`.)
2. Edit `<app>/ks.yaml`: REMOVE `../../../../components/postgress`, and remove the Crunchy
   `dependsOn: crunchy-postgres-operator`, the `PostgresCluster` `healthCheckExprs`, and any `POOL_MODE`
   substitution. Commit, push, `flux reconcile kustomization <app> -n <ns>`.
3. Flux prunes the Crunchy `PostgresCluster` (CR + pods + secrets + PVCs gone in ~20s). Confirm app still healthy.

## Per-app specifics

Order (lowest-risk first): **radarr → sonarr → mealie → paperless → lubelogger → ghostfolio → securo → authentik**.

| App | ns | Deploy replicas | DB wiring change (Stage 3) | Stage-1/4 notes |
|---|---|---|---|---|
| **radarr** | default | HPA? no, Deployment | `RADARR__POSTGRES__HOST: radarr-pgbouncer.default.svc` → `postgres-radarr-rw.database.svc`; password secret `radarr-pguser-radarr` → `postgres-radarr-app` | ks also has `components/zeroscaler` (keep). No crunchy `dependsOn`/health block. |
| **sonarr** | default | Deployment | `SONARR__POSTGRES__HOST` → `postgres-sonarr-rw.database.svc`; secret → `postgres-sonarr-app` | same as radarr (zeroscaler, no crunchy dep block) |
| **mealie** | default | Deployment | `POSTGRES_SERVER: mealie-pgbouncer.default.svc` → `postgres-mealie-rw.database.svc`; secret `mealie-pguser-mealie` → `postgres-mealie-app` | ks HAS crunchy `dependsOn` + `ProxyAvailable` health → remove in Stage 4. `KOPIUR_CAPACITY: 3Gi` |
| **paperless** | default | Deployment | `PAPERLESS_DBHOST: paperless-pgbouncer.default.svc` → `postgres-paperless-rw.database.svc`; secret `paperless-pguser-paperless` → `postgres-paperless-app` | ks HAS crunchy dep+health AND `paperless-dragonfly` dep (keep dragonfly). zeroscaler (keep). |
| **lubelogger** | default | Deployment | Uses a `lubelogger-postgres` **SecretStore** + ExternalSecret that builds `POSTGRES_CONNECTION` from `lubelogger-pguser-lubelogger` keys. Repoint that ES `extract.key` → `postgres-lubelogger-app`, and fix key refs (`pg_pgbouncer-host`→`host`, `pg_user`→`username`, keep `pg_port/pg_password/pg_dbname`→`port/password/dbname`). host is already in the mirrored secret as FQDN. | Already uses the k8s-provider mirror pattern (its `secretstore.yaml`/`rbac.yaml`). The `credentials-mirror` component REPLACES its hand-rolled SecretStore+RBAC — reconcile carefully to avoid dupes (mirror SecretStore is `postgres-lubelogger`, its existing one is `lubelogger-postgres`). Simplest: keep the component, delete `lubelogger/app/secretstore.yaml`+`rbac.yaml`, repoint `externalsecret.yaml` at `postgres-lubelogger-app` via store `postgres-lubelogger`. `KOPIUR_CAPACITY: 2Gi`, `GATUS_*` substitutions stay. |
| **ghostfolio** | default | Deployment | `DATABASE_URL` from secret `ghostfolio-pguser-ghostfolio` key `pgbouncer-uri` → secret `postgres-ghostfolio-app` key `uri` | ks has crunchy dep+health AND `ghostfolio-dragonfly` (keep). No `KOPIUR` (no kopiur backup component). |
| **securo** | default | 2 containers: `01-migrate` (init) + app; env is a **list** (`&env`) | `DATABASE_URL: postgresql+asyncpg://securo:$(PG_PASS)@securo-pgbouncer.default.svc:5432/securo` → `...@postgres-securo-rw.database.svc:5432/securo`; `PG_PASS` secret `securo-pguser-securo` → `postgres-securo-app` | **pgvector**: stock CNPG `17.11` bundles `vector` + `pgcrypto` (verified) — NO custom image. Port `database-init-cm.sql` (`CREATE EXTENSION IF NOT EXISTS vector` + `GRANT ALL ON SCHEMA public TO securo` + `ALTER SCHEMA public OWNER TO securo`) into the CNPG cluster via `bootstrap.initdb.postInitApplicationSQL` (needs a per-app cluster patch in `db/postgres/app` — see securo note). Delete securo's two Crunchy `kustomization.yaml` patches (databaseInitSQL + dataSource-remove) in Stage 4. `KOPIUR_CAPACITY: 5Gi`, `securo-dragonfly` dep stays. |
| **authentik** | **security** | server+worker (server has HPA `minReplicas:1`) | `AUTHENTIK_POSTGRESQL__HOST: authentik-pgbouncer.security.svc` → `postgres-authentik-rw.database.svc`; remove `AUTHENTIK_POSTGRESQL__USE_PGBOUNCER`; password secret `authentik-pguser-authentik` → `postgres-authentik-app`; keep `SSLMODE: require` | **ns=security** — pass `security` as arg2 to the script; `APP_NAMESPACE: security` in both ks files. Remove `POOL_MODE: transaction` substitution in Stage 4. LAST + most careful (SSO outage blocks other logins, but they keep working if already authed). Scale BOTH server+worker to 0 in Stage 2 (script scales `deploy/authentik-server`? verify workload names — set `DEPLOY_NAME`). |

### securo `postInitApplicationSQL` patch (Stage 1)
Because the extension must exist before the app's alembic migration runs, add to `securo/db/postgres/app/kustomization.yaml`
a patch on the CNPG `Cluster` injecting:
```yaml
spec:
  bootstrap:
    initdb:
      postInitApplicationSQL:
        - CREATE EXTENSION IF NOT EXISTS vector
        - GRANT ALL ON SCHEMA public TO securo
        - ALTER SCHEMA public OWNER TO securo
```
(`postInitApplicationSQL` runs as superuser in the app database — correct scope for an untrusted extension.)

### authentik workload scaling (Stage 2)
Authentik runs a `server` Deployment and a `worker` Deployment. The data script only scales one workload.
Scale both to 0 manually before running the dump, or run the script with `DEPLOY_NAME=authentik-server` and
`kubectl scale deploy/authentik-worker -n security --replicas 0` alongside. Bring both back in Stage 3.

## Verification checklist (per app)
- [ ] Stage 1: `postgres-<app>` Cluster Ready 3/3; `postgres-<app>-app` secret in app ns; app still on Crunchy.
- [ ] Stage 2: `scripts/cnpg-migrate-data.sh` prints `VERIFY OK` (identical row counts).
- [ ] Stage 3: app pod Ready, logs "Postgres 17.x" + migrations, healthcheck OK, 0 restarts, host env = CNPG.
- [ ] Stage 4: on-demand Backup `completed` → `s3://cnpg/<app>`; Crunchy `PostgresCluster` pruned; app healthy.

## After all 8 remaining apps
- Remove `components/postgress` from the tree (nothing but immich would reference it — and immich never did;
  it uses its own inline cluster). Do a repo-wide grep to confirm no non-immich refs remain.
- **Keep** the Crunchy operator (`crunchy-postgres`) + MinIO `postgress` bucket — immich still needs them.
- Clean up the throwaway Garage `s3://cnpg/testpg` objects from Phase A (optional).
