# Per-app database pattern (Dragonfly → adopt for Postgres)

The final approach used to migrate from a shared Dragonfly to one authenticated instance per app.
Document exists so the same structure can be adopted for a per-app Postgres later. The Dragonfly
migration is **complete**: all four apps (securo, ghostfolio, paperless, immich) run dedicated
authenticated instances; the shared `dragonfly-cluster` was removed (only the operator remains).

## Core ideas

- **One central operator** stays in `database` (Dragonfly operator; for Postgres, the crunchy PGO).
- **One instance per app**, defined by a reusable Flux **Component**, driven by a per-app Flux
  Kustomization.
- App-owned DB config lives **under the app directory** (`<app>/db/<engine>/`), but all rendered
  runtime resources deploy into the shared **`database`** namespace via `targetNamespace: database`.
- **Per-engine split**: `<app>/db/dragonfly/`, future `<app>/db/postgres/` — each its own Flux
  Kustomization so operator deps, health checks, and retries are independent.
- **Authentication on from day one**; password is user-managed in the app's existing 1Password item.

## Repository structure

```
kubernetes/components/dragonfly/          # reusable component (adopt as components/<engine>/)
├── kustomization.yaml                    # kind: Component; lists the resources below
├── cluster.yaml                          # the CR, name: dragonfly-${APP}
├── podmonitor.yaml
├── networkpolicy-client.yaml             # allow app -> instance
├── networkpolicy-prometheus-metrics.yaml # allow observability/prometheus -> metrics
└── authentication/
    └── kustomization.yaml                # kind: Component; patches auth password into the CR

kubernetes/apps/default/<app>/
├── ks.yaml                               # the app; dependsOn <app>-dragonfly
├── app/
│   ├── kustomization.yaml
│   ├── helmrelease.yaml
│   └── externalsecret.yaml               # app-side: password folded in here (see below)
└── db/
    └── dragonfly/
        ├── ks.yaml                       # Flux Kustomization: <app>-dragonfly
        └── app/
            ├── kustomization.yaml
            └── dragonfly-auth.externalsecret.yaml   # database-side auth secret
```

Register the DB Kustomization in `kubernetes/apps/default/kustomization.yaml`:
```yaml
resources:
  - ./<app>/ks.yaml
  - ./<app>/db/dragonfly/ks.yaml
```

## Naming convention

- **Runtime resources** in `database` ns → `dragonfly-${APP}` (CR/pods/svc, `app:` label, podmonitor,
  both NetworkPolicies, auth secret `dragonfly-${APP}-auth`). Groups them together in
  `kubectl get -n database`.
- **Connection host** → `dragonfly-${APP}.database.svc.cluster.local:6379`.
- **Flux Kustomization object** (lives in `default` ns) → `${APP}-dragonfly`, so it sorts next to its
  app. This is the one intentional inversion.

## Reusable component

`kustomization.yaml` — `apiVersion: kustomize.config.k8s.io/v1alpha1`, `kind: Component`, listing
`cluster.yaml`, `podmonitor.yaml`, and both networkpolicies. No `patches` (unlike the upstream
onedr0p/joryirving component — we do **not** copy their HelmRelease `dependsOn` patch; the DB
Kustomization depends on the operator directly).

`cluster.yaml` — the CR, sized via substitutions with defaults:
```yaml
metadata:
  name: dragonfly-${APP}
spec:
  replicas: ${DRAGONFLY_REPLICAS:=1}
  args:
    - --maxmemory=$(MAX_MEMORY)Mi
    - --proactor_threads=${DRAGONFLY_THREADS:=1}
  resources:
    limits:
      memory: ${DRAGONFLY_MEMORY:=256Mi}
  topologySpreadConstraints:
    - labelSelector:
        matchLabels:
          app: dragonfly-${APP}     # narrowed to THIS instance, not part-of: dragonfly
```

`authentication/kustomization.yaml` — a second `kind: Component` that patches auth into the CR;
consumers supply `${DRAGONFLY_PASSWORD_SECRET}`:
```yaml
patches:
  - target: { group: dragonflydb.io, version: v1alpha1, kind: Dragonfly }
    patch: |-
      - op: add
        path: /spec/authentication
        value:
          passwordFromSecret:
            key: password
            name: ${DRAGONFLY_PASSWORD_SECRET}
```

## Per-app DB Kustomization (`<app>/db/dragonfly/ks.yaml`)

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: <app>-dragonfly
spec:
  components:
    - ../../../../../../components/dragonfly            # note depth: 6 up from db/dragonfly/
    - ../../../../../../components/dragonfly/authentication
  dependsOn:
    - { name: dragonfly, namespace: database }          # the operator
    - { name: onepassword, namespace: external-secrets }
  healthCheckExprs:
    - apiVersion: dragonflydb.io/v1alpha1
      kind: Dragonfly
      failed: status.phase != 'Ready'                   # capital R — see gotchas
      current: status.phase == 'Ready'
    - apiVersion: external-secrets.io/v1
      kind: ExternalSecret
      failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
      current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
  path: ./kubernetes/apps/default/<app>/db/dragonfly/app
  targetNamespace: database
  wait: true
  postBuild:
    substitute:
      APP: <app>
      APP_NAMESPACE: default
      DRAGONFLY_PASSWORD_SECRET: dragonfly-<app>-auth
      # DRAGONFLY_MEMORY / DRAGONFLY_THREADS / DRAGONFLY_REPLICAS — only if overriding defaults
```

The Kustomization object lands in `default` (registered by the parent `default/kustomization.yaml`);
its rendered resources land in `database` via `targetNamespace`.

## Password wiring (two independent ESO syncs, no cross-namespace copy)

Add a `DRAGONFLY_PASSWORD` field to the app's existing 1Password item. **Alphanumeric only** — it gets
baked into a `redis://:PASS@host` URL, and symbols would need percent-encoding ESO won't do.

Two ExternalSecrets, both extracting the same field from the same 1Password item, synced independently:

```
                            ┌─ Secret/database/dragonfly-<app>-auth   (db/dragonfly/app/...externalsecret.yaml)
1Password/<app> ────────────┤
                            └─ Secret/default/dragonfly-<app>-auth    (app-side)
```

- **Database side**: `<app>/db/dragonfly/app/dragonfly-auth.externalsecret.yaml` → creates
  `dragonfly-<app>-auth` in `database`, consumed by the CR's `passwordFromSecret`.
- **App side**: fold into the app's **existing** `externalsecret.yaml` — do not add a separate app-side
  auth ExternalSecret unless the existing one can't carry env (immich was the exception: its existing
  ExternalSecret produces a config *file*, so it got a second ExternalSecret document appended to the
  same file).

Do **not** use Kubernetes-provider cross-namespace Secret sync for user-managed passwords — 1Password
is the single source of truth, so sync both namespaces from it directly. Reserve K8s-provider sync for
operator-generated credentials (e.g. PGO's `<app>-pguser-<app>`, for the future Postgres adoption).

## Consuming the password in the app

The app must have `reloader.stakater.com/auto: "true"` so it restarts on password rotation.

- **Discrete env var app** (e.g. ghostfolio `REDIS_PASSWORD`): add it to the app's ExternalSecret and
  deliver via `envFrom` — simplest.
- **URL app** (e.g. paperless `PAPERLESS_REDIS`, securo `REDIS_URL`): bake the whole password-embedded
  URL into the app's ExternalSecret:
  `redis://:{{ .DRAGONFLY_PASSWORD }}@dragonfly-<app>.database.svc.cluster.local:6379/0`, delivered via
  `envFrom`. **Do not** try `redis://:$(REDIS_PASS)@...` with an inline env value — Kubernetes `$(VAR)`
  expansion cannot see `envFrom`-sourced vars, only inline `env:` entries defined earlier in the same
  container. Baking the full URL in the secret sidesteps this entirely.
- Since each app has its own instance, use DB index **0** — logical index isolation is no longer needed.

## Gotchas (all hit during the Dragonfly rollout)

- **Memory/thread floor**: Dragonfly needs 256 MiB **per proactor thread**. `--proactor_threads=2` with
  a 256Mi limit crashes (`512.00MiB are required. Exiting`). Keep threads=1 for 256Mi; immich uses
  512Mi/2 for spiky job queues.
- **Health phase casing**: the operator reports `status.phase: Ready` (capital R). The upstream
  reference and old copies used lowercase `'ready'` — that never matches and blocks forever under
  `wait: true`.
- **Operator rollout lag**: changing CR args updates the StatefulSet but a crash-looping pod may not
  roll; `kubectl delete pod dragonfly-<app>-0` forces recreation with the new spec.
- **Explicit env beats envFrom**: an inline `env:` entry overrides an `envFrom` value of the same name,
  so when moving a value into the secret, remove the old inline/helmrelease copy.

## Adopting for Postgres later

Same structure, different engine dir:

```
<app>/db/
├── dragonfly/ ...
└── postgres/
    ├── ks.yaml                        # Flux Kustomization: <app>-postgres
    └── app/
        ├── kustomization.yaml
        ├── postgres-credentials.externalsecret.yaml   # mirror PGO secret -> app ns
        └── postgres-init.{configmap,sql}              # optional init
```

Key differences from Dragonfly:
- Depend on `crunchy-postgres-operator` (ns database) instead of the dragonfly operator.
- Add a `PostgresCluster` health expression.
- Postgres credentials are **operator-generated** (PGO creates `<app>-pguser-<app>` in `database`), not
  user-managed. Mirror that Secret into the app namespace with an **External Secrets Kubernetes
  provider** (a read-only `ClusterSecretStore` exposing `database` Secrets), not from 1Password:
  ```
  PGO Secret/database/<app>-pguser-<app>  ──ESO k8s provider──►  Secret/<app-ns>/<app>-pguser-<app>
  ```
- Note the existing `components/postgress` currently renders the PostgresCluster into the *app's own*
  namespace via the app ks (not a separate db Kustomization). Adopting this pattern means moving it to
  `<app>/db/postgres/` with `targetNamespace: database` and mirroring credentials back — that's the
  future work this doc is for.

So: user-managed creds (Dragonfly) sync from 1Password into both namespaces; operator-generated creds
(Postgres) mirror from `database` into the app namespace; both engines managed by the same per-app
`<app>/db/<engine>/` Kustomizations.
```
