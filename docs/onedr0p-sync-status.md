# onedr0p home-ops sync status

Analysis of when and how far `flux-homelab` was synced from
[onedr0p/home-ops](https://github.com/onedr0p/home-ops), and what remains unsynced.

_Generated 2026-09-06. Local `home-ops` checkout was last fetched to HEAD
`9e02025f5f` (2026-07-19) — that is the fetch point, not a sync point._

## TL;DR

There were **two distinct sync episodes**, not one:

1. **March 2025 — the "total recreation."** Almost the entire repo was rebuilt
   against onedr0p's structure, then his updates were actively followed for
   ~2.5 months (April → mid-June 2025).
2. **January 2026 — a lighter bulk catch-up.** A second resync ~6 months later
   that pulled most (not all) of the June 2025 → Jan 2026 infra work, plus a
   short tail of hand-picked apps (agregarr, overseerr). Following stopped for
   good after **2026-01-16**.

Everything in home-ops after **~2026-01-14** is unsynced. Some June 2025 → Jan
2026 items were also skipped by the Jan batch (notably the observability
modernization).

## Sync boundaries

| Episode | Your side (flux-homelab) | Date | onedr0p side (synced-to) |
|---|---|---|---|
| **1. Total recreation** | `a5be740d` feat: update codebase (391 files, +4253/−5024) | 2025-03-31 | home-ops ~`0a0780dffd` (2025-03-31) |
| ↳ followed him actively | through `49e7c03d` feat(cluster): migrate to home-operations | ~2025-06-14 | ~early–mid June 2025 |
| **2. Second catch-up** | `b86bb989` / `9bde5008` !feat: apply latest updates (420 files) | 2026-01-13/14 | home-ops ~`0779b068cd` (2026-01-14) |
| ↳ last adaptation | `5fb81d85` feat(agregarr): deploy | 2026-01-16 | his agregarr `2a636e81fb` (2026-01-13) |

### How these were pinned

- **March 2025 recreation:** your `.taskfiles/volsync/Taskfile.yaml` from
  `a5be740d` is a **verbatim copy** of home-ops's — only 2 lines differ, and
  those are your own `storage`-namespace customization (vs his
  `volsync-system`). That file was stable in home-ops across 2025-03-14 →
  2025-03-31. An explicit `feat(coredns): following onedr0p changes`
  (`5dcbfddc`, 2025-04-29) confirms active following afterward.
- **Jan 2026 catch-up:** the two `!feat: apply latest updates` commits carry
  merge-conflict markers in their bodies — the signature of a long-overdue bulk
  pull. agregarr, which onedr0p deployed 2026-01-13, was picked up by you
  2026-01-16.

> Note: the Sep 2026 kopia work (`255f82f0`…`2795378c`) is **not** a sync — it's
> your own re-implementation of onedr0p's much earlier volsync→kopiur migration
> (his was Jul 2026). It does not move the sync boundary.

## June 2025 → Jan 2026 window: what synced vs. what didn't

The Jan 2026 batch was a genuine content sync and caught most infra work from
this window. But it skipped some items, and you deliberately diverged on others.

### Came through (present in your repo today)

- **gatus-sidecar** (his 2025-09-30) ✅
- **tuppr** for Talos upgrades (2025-09) ✅
- **multus → bjw-s/home-operations chart with CRD** (2025-10) ✅
- **envoy-gateway** ✅ — onedr0p churned cilium → istio → envoy-gateway (Sep
  2025) and remains on envoy at HEAD. You're on the same endpoint, so nothing
  to do here.

### Did NOT come through (still unsynced within this window)

| onedr0p change | Date | Your repo | Note |
|---|---|---|---|
| **grafana-operator** (replaces kps-embedded Grafana; dashboards as `GrafanaDashboard` CRs) | 2025-10-13 | ❌ plain `grafana` Helm + `instance/grafana.yaml` | biggest structural gap |
| **`observability` → `o11y` namespace rename** | 2025-10 | ❌ still `observability` | cosmetic but touches every path in the folder |
| **silence-operator** (official OCI chart) | 2025-11-05 | ❌ absent | alertmanager silencing |
| **intel DRA / CDI GPU migration** | 2025-10-07 | ⚠️ partial | `plex/ks.yaml` references intel-dra, but not the full device-plugin migration |
| **talos hostname / net config migration** | 2025-12-22/23 | ❔ verify your talos config | machine-config structure change |

### Deliberate divergences (skip — different by choice)

- **Logging:** you run **fluent-bit + victoria-logs**; onedr0p migrated
  **promtail → alloy** (2025-07-22). Different stack entirely.
- **Requests:** you moved to **external overseerr** (`30bf236a`, 2026-01-16);
  onedr0p migrated to **seerr** (2025-11-15).
- **Apps he runs that you don't:** thelounge, dispatcharr, ghost, nzbget,
  emby/watchstate, smtp-relay. Lifestyle choices, not sync gaps.

## After Jan 2026: fully unsynced

None of onedr0p's post-January distinctive work landed in your repo:

- **chaski** — replaced his notifier (2026-06)
- **echo** chart migration (2026-06)
- **konflate**
- **gatus-sidecar chart migration** (2026-06; you have the sidecar but not this
  refactor)
- **openebs → miroir** replicated block CSI storage migration (2026-07)
- **kata-containers** system extension (2026-07)
- newer **home-operations org self-hosted runner** setup (2026-07)

## Suggested catch-up, prioritized

**Infra you'd likely want:**
1. grafana-operator + `GrafanaDashboard` CRs (modernizes dashboard management)
2. silence-operator
3. openebs → miroir storage migration (large; his Jul 2026 work)
4. Full intel DRA/CDI GPU migration
5. `observability` → `o11y` rename (do alongside the grafana-operator work)

**Newer tooling to evaluate:** chaski (notifier), echo/konflate charts,
kata-containers.

**Skip (deliberate divergences):** alloy (you use fluent-bit/victoria-logs),
seerr (you use external overseerr), his personal app deployments.

To generate the raw catch-up commit list, diff onedr0p's human (non-bot)
commits from `0779b068cd` (2026-01-14) forward.
