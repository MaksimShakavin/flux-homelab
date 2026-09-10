# postgres

CloudNativePG-backed Postgres component. The default Postgres for apps in this repo, replacing the
retired CrunchyData PGO setup (`components/postgress`). Each consuming app gets its own dedicated CNPG
`Cluster` in the `database` namespace, following the per-app-db pattern (`docs/per-app-db-pattern.md`).

## Layout

| File | Purpose |
| --- | --- |
| `cluster.yaml` | The CNPG `Cluster` CR — `postgres-${APP}` in `database`, `initdb` bootstrap, barman-cloud plugin as WAL archiver. |
| `objectstore.yaml` | `ObjectStore` CR (`postgres-${APP}`) — barman-cloud plugin backup config → Garage `s3://cnpg/${APP}`. |
| `scheduledbackup.yaml` | Daily `ScheduledBackup` (`postgres-${APP}-daily`), `method: plugin`. |
| `externalsecret.yaml` | Barman S3 creds `postgres-${APP}-backup` (pulled from the 1Password `garage-buckets` item). |
| `credentials-mirror/` | Optional sub-component: mirrors the operator-generated `postgres-${APP}-app` secret into the app's namespace (see below). |

Backups use the **barman-cloud plugin** (`ObjectStore` CRD + `.spec.plugins`), not the deprecated
in-tree `.spec.backup.barmanObjectStore`. The plugin (`plugin-barman-cloud`) is installed alongside
the operator in `database`; consuming apps must `dependsOn` the `cnpg-barman-plugin` Kustomization.

## Substitution variables

Set these in the consuming Flux Kustomization's `postBuild.substitute`.

| Variable | Default | Notes |
| --- | --- | --- |
| `APP` | _(required)_ | Consuming app — names the cluster, secrets, backup path, DB, and owner role. |
| `APP_NAMESPACE` | _(required)_ | The app's namespace — where `credentials-mirror` writes the `-app` secret. |
| `POSTGRES_REPLICAS` | `3` | Cluster instance count. |
| `POSTGRES_IMAGE` | `ghcr.io/cloudnative-pg/postgresql:18-standard-trixie` | Postgres image (the `standard` flavor bundles `pgvector`, `pgaudit`, failover slots, LLVM JIT). |
| `POSTGRES_SIZE` | `5Gi` | Per-instance PVC size (`local-hostpath`). |
| `POSTGRES_RETENTION` | `30d` | Barman retention policy. |

## Bootstrap behavior

The `Cluster` bootstraps with plain `initdb` — it creates a database and owner role both named `${APP}`,
and CNPG generates that role's password into the `postgres-${APP}-app` secret. This is an
empty-cluster bootstrap, not a restore; data is loaded separately (e.g. the Crunchy→CNPG cutover used a
one-shot `pg_dump | pg_restore`, see `docs/cnpg-migration-runbook.md`).

Adding a net-new app is just:

```yaml
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: myapp-postgres
spec:
  components:
    - ../../../../../../components/postgres
  dependsOn:
    - name: cloudnative-pg
      namespace: database
    - name: cnpg-barman-plugin
      namespace: database
    - name: onepassword
      namespace: external-secrets
  healthCheckExprs:
    - apiVersion: postgresql.cnpg.io/v1
      kind: Cluster
      failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
      current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
  interval: 1h
  path: ./kubernetes/apps/<ns>/myapp/db/postgres/app
  targetNamespace: database
  wait: true
  sourceRef:
    kind: GitRepository
    name: flux-system
    namespace: flux-system
  postBuild:
    substitute:
      APP: myapp
      APP_NAMESPACE: <ns>
```

The `db/postgres/app/kustomization.yaml` alongside it is `resources: []` — the component supplies
everything. To run extra SQL at bootstrap (e.g. an extension), patch the `Cluster`'s
`bootstrap.initdb.postInitApplicationSQL` in that file; target `kind: Cluster` with **no name** (the patch
runs before Flux substitutes `${APP}`, so the name is still the literal `postgres-${APP}`).

## Backups

- Continuous WAL archiving + base backups via the **barman-cloud plugin** to **Garage** at
  `s3://cnpg/${APP}` (`serverName: ${APP}`, endpoint `https://garage-s3.exelent.click`, `bzip2`
  compression). Config lives in the `ObjectStore` CR (`objectstore.yaml`); the `Cluster` references
  it via `.spec.plugins` with `isWALArchiver: true`.
- Daily `ScheduledBackup` at **04:40** (`scheduledbackup.yaml`, cron `0 40 4 * * *`, `method: plugin`).
- `retentionPolicy: ${POSTGRES_RETENTION:=30d}`.
- S3 creds come from `postgres-${APP}-backup` (an ExternalSecret reading the shared `garage-buckets`
  1Password item; all apps share one `cnpg` key and are isolated by `serverName`/`destinationPath`).

On-demand backup (e.g. a pre-change cutover snapshot):

```sh
kubectl apply -f - <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Backup
metadata: { name: postgres-${APP}-manual, namespace: database }
spec:
  method: plugin
  pluginConfiguration: { name: barman-cloud.cloudnative-pg.io }
  cluster: { name: postgres-${APP} }
EOF
# check: use the FQ resource — `backup` short-name resolves to Longhorn
kubectl get backups.postgresql.cnpg.io -n database postgres-${APP}-manual \
  -o jsonpath='{.status.phase} {.status.backupName}'
```

## Connecting from an app

CNPG generates `postgres-${APP}-app` **in the `database` namespace** with keys `uri`, `jdbc-uri`,
`username`, `user`, `password`, `dbname`, `port`, `host`. Because that secret's `host` is the bare
`postgres-${APP}-rw` service name (won't resolve cross-namespace), apps consume the **mirrored** copy
produced by the `credentials-mirror` sub-component, which rewrites `host`/`uri`/`jdbc-uri` to the FQDN
`postgres-${APP}-rw.database.svc.cluster.local`.

Add the mirror to the app's own Flux Kustomization (not the db one):

```yaml
spec:
  components:
    - ../../../../components/postgres/credentials-mirror
  postBuild:
    substitute:
      APP: myapp
      APP_NAMESPACE: <ns>
```

Then reference `postgres-${APP}-app` in the app's namespace:

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: postgres-myapp-app
        key: uri
```

The `-rw` service points at the primary — apps connect **directly**, there is no `Pooler`/PgBouncer in
this component. If transaction-mode pooling is ever needed, add a `Pooler` CR per cluster as a follow-up.

## Health check expression

The db Kustomization gates on the `Cluster` reaching Ready (also let the app Kustomization
`dependsOn` the db one, so the workload only reconciles once the DB is healthy):

```yaml
healthCheckExprs:
  - apiVersion: postgresql.cnpg.io/v1
    kind: Cluster
    failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
    current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```
