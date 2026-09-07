# Agent task: migrate ONE app from Crunchy PGO → CloudNative-PG

You are migrating a single Kubernetes app's Postgres from Crunchy PGO to CloudNative-PG (CNPG) in a live
FluxCD homelab. The framework (CNPG operator, `kubernetes/components/postgres`, Garage `cnpg` bucket) is
already installed and verified; **prowlarr is already migrated as the reference**. Do exactly ONE app.

## Inputs (fill these in when dispatching)
- `APP`: <app name, e.g. radarr>
- `APP_NS`: <namespace — `default` for all except authentik which is `security`>
- Read `docs/cnpg-migration-runbook.md` FIRST — the per-app table has the exact HR wiring change, extra
  components to keep (zeroscaler/dragonfly), whether a Crunchy `dependsOn`/health/`POOL_MODE` block exists,
  and any special handling (securo pgvector, authentik two workloads).

## Environment
- Repo root is the cwd. `export KUBECONFIG=$PWD/kubeconfig` for all kubectl/flux.
- Commit style: one-line conventional commits, NO body, NO Co-Authored-By. User pushes to `main` directly
  (you push too — this is a live GitOps cutover; Flux only sees pushed commits).
- `git push origin main` then `flux reconcile ...` after every commit — nothing applies until pushed.
- Use the reference app `prowlarr` as a concrete template: `kubernetes/apps/default/prowlarr/db/postgres/`,
  its `ks.yaml` components, and `app/helmrelease.yaml` DB block show the exact shape.

## The golden rule
NEVER cut over in one commit. Crunchy stays a hot, read-only fallback until the app is verified on CNPG.
Do it in the four stages below (3 commits + one live data step). If anything looks wrong, STOP and report —
do not remove `components/postgress` until Stage 4.

## Procedure

### Stage 1 — stand up empty CNPG alongside Crunchy (commit 1)
1. Create `kubernetes/apps/<APP_NS>/<APP>/db/postgres/ks.yaml` (copy prowlarr's, change `metadata.name` to
   `<APP>-postgres`, `path` to `.../<APP_NS>/<APP>/db/postgres/app`, and `substitute.APP`/`APP_NAMESPACE`).
   Add per-app `postBuild.substitute` overrides from the runbook (e.g. `POSTGRES_SIZE`).
2. Create `kubernetes/apps/<APP_NS>/<APP>/db/postgres/app/kustomization.yaml` with `resources: []`
   (securo: this file also carries the `postInitApplicationSQL` Cluster patch — see runbook).
3. Edit `<APP>/ks.yaml`: ADD `../../../../components/postgres/credentials-mirror` to `components`,
   KEEP `../../../../components/postgress`, add `APP_NAMESPACE: <APP_NS>` to `substitute`. (authentik's
   component path depth is `../../../../` from `security/authentik` — same depth.)
4. Register `./<APP>/db/postgres/ks.yaml` in `kubernetes/apps/<APP_NS>/kustomization.yaml`.
5. Validate: `flux build kustomization <APP>-postgres --path ./kubernetes/apps/<APP_NS>/<APP>/db/postgres/app --kustomization-file ./kubernetes/apps/<APP_NS>/<APP>/db/postgres/ks.yaml --dry-run` renders a `Cluster postgres-<APP>` in `database`. Also `flux build kustomization <APP> ...` still shows BOTH the Crunchy `PostgresCluster/<APP>` and the new mirror stack.
6. Commit `feat(<APP>): stand up CNPG alongside crunchy (stage 1)`, push, `flux reconcile kustomization cluster-apps --with-source`.
7. Wait: `kubectl get cluster.postgresql.cnpg.io -n database postgres-<APP>` Ready 3/3;
   `kubectl get secret -n <APP_NS> postgres-<APP>-app` exists; app still Running on Crunchy.
   If `<APP>-postgres` Kustomization is `False` from the transient bootstrap `Failed` phase, run
   `flux reconcile kustomization <APP>-postgres -n <APP_NS>` — it self-heals once the Cluster is Ready.

### Stage 2 — move the data (NO commit)
Run: `scripts/cnpg-migrate-data.sh <APP> <APP_NS>`
- It scales the app to 0, dumps from Crunchy `<APP>-primary.<APP_NS>.svc`, restores into CNPG, prints an
  exact row-count diff. Expect ~6 filtered `_crunchypgbouncer` ACL errors (harmless).
- Require `VERIFY OK`. If it prints a DIFF, STOP and report (do NOT proceed to Stage 3).
- authentik: also `kubectl scale deploy/authentik-worker -n security --replicas 0` before/around the script
  (it only scales one workload) — see runbook.

### Stage 3 — repoint the app (commit 2; Crunchy still fallback)
1. Edit `<APP>/app/helmrelease.yaml` DB wiring per the runbook's per-app row (host → `postgres-<APP>-rw.database.svc`,
   password/URI secret → `postgres-<APP>-app`). Leave `components/postgress` in place.
   (lubelogger/ghostfolio/securo/authentik have non-standard wiring — follow the table exactly.)
2. Commit `feat(<APP>): repoint to CNPG, keep crunchy fallback (stage 3)`, push,
   `flux reconcile kustomization <APP> -n <APP_NS> --with-source` then `flux reconcile helmrelease <APP> -n <APP_NS>`
   (the second restores replicas we scaled to 0 + applies new env).
3. Verify: app pod Ready & 0 restarts; `kubectl logs` shows it connected to Postgres 17.x and ran migrations;
   app healthcheck OK (port-forward + curl its liveness path). If broken → revert commit 2, push, reconcile
   (app returns to Crunchy with all data) and report.

### Stage 4 — retire Crunchy for this app (commit 3, only after Stage 3 verified)
1. On-demand backup + confirm Garage:
   `kubectl apply` a `Backup` (name `postgres-<APP>-cutover`, `method: barmanObjectStore`, `cluster.name: postgres-<APP>`),
   then check `kubectl get backups.postgresql.cnpg.io -n database postgres-<APP>-cutover -o jsonpath='{.status.phase} {.status.destinationPath}'`
   → `completed s3://cnpg/<APP>`. (Use the FQ `backups.postgresql.cnpg.io` — `backup` = Longhorn.)
2. Edit `<APP>/ks.yaml`: REMOVE `../../../../components/postgress`; if present, remove the Crunchy
   `dependsOn: crunchy-postgres-operator`, the `PostgresCluster` `healthCheckExprs`, and any `POOL_MODE`
   substitution. (securo: also delete its two Crunchy `kustomization.yaml` patches.)
3. Commit `feat(<APP>): retire crunchy postgres (stage 4)`, push, `flux reconcile kustomization <APP> -n <APP_NS>`.
4. Confirm Flux pruned the Crunchy `PostgresCluster/<APP>` (CR/pods/secrets/PVCs gone) and the app is still healthy.

## Report back
For the one app: which stages completed, the `VERIFY OK`/diff result, Stage-3 healthcheck result, the Garage
backup path, and confirmation Crunchy was pruned. Note anything that diverged from the runbook.

## Guardrails
- Touch ONLY this app's files + the parent `kustomization.yaml`. Do not modify `components/postgres`,
  the operator, other apps, or immich.
- Do not delete/recreate any PVC. Do not touch Crunchy until Stage 4. If a stage's verification fails, STOP.
- immich is out of scope; the Crunchy operator + MinIO stay.
