# qBittorrent + emonoda torrent-file flow

This stack lets the \*arr automations behave in the [rutracker](https://rutracker.org)
world. On rutracker, TV shows are published as season packs — when a new episode
airs, the uploader adds it to the *same* pack and re-creates the torrent. emonoda
catches those re-created torrents and re-uploads them to qBittorrent, keeping the
season pack up to date automatically. qbit-torrent-files-cleaner is the housekeeping half of that
flow (see below).

Two CronJobs cooperate around qBittorrent's finished-torrent export dir:
`/data/torrents/.torrents/completed` (shared via the NFS `/data` mount). Both run in
`Europe/Warsaw` with `concurrencyPolicy: Forbid`:

| Runs                | Cron          | App                | Role                                              |
| ------------------- | ------------- | ------------------ | ------------------------------------------------- |
| Every 2h, on :00    | `0 */2 * * *` | qbit_manage        | Recheck + tagging. Does not touch the export dir. |
| Every hour, on :30  | `30 * * * *`  | rutracker-pipeline | The three-step rutracker sequence below.          |

`qbit_manage`'s recheck is heavy (up to ~1.2h on a large cycle), so it runs every 2h
rather than hourly to fit inside its window.

## The rutracker pipeline

`rutracker-pipeline` is a single CronJob that runs three steps **in a fixed order with
fail-fast**, using Kubernetes init containers — each step must succeed before the next
starts:

| Step | Container     | App / task                                       | Role                                                                    |
| ---- | ------------- | ------------------------------------------------ | ----------------------------------------------------------------------- |
| 1    | initContainer | emonoda `emupdate`                               | Refreshes the live `.torrent` files from re-created rutracker packs.    |
| 2    | initContainer | qbit-torrent-files-cleaner `handle_unregistered` | Blocklists tracker-deleted torrents; \*arr redownloads a replacement.   |
| 3    | main          | qbit-torrent-files-cleaner `monitor_completed`   | Prunes exported `.torrent` files no longer in the client.               |

The order is deliberate and **guarded**: if emonoda fails, neither of the other two runs;
if handle_unregistered fails, monitor_completed doesn't run. emonoda refreshes the live
set first; handle_unregistered then removes a dead torrent, whose exported `.torrent`
becomes an orphan that monitor_completed prunes in the same run. (A later step failing
re-runs the earlier — idempotent — steps from the top; `backoffLimit` keeps retries small.)

Steps 2 and 3 are two tasks of the
[same tool](https://github.com/MaksimShakavin/qbit-torrent-files-cleaner). Because the
whole sequence runs in one pod, emonoda mounts qBittorrent's ReadWriteOnce config PVC and
the job uses `podAffinity` to co-locate on qBittorrent's node.

## Why qbit-torrent-files-cleaner is needed

qBittorrent's `FinishedTorrentExportDir` is **append-only by design** — libtorrent
keeps no reference to the exported files, so it never deletes one when the torrent
is removed (see [qBittorrent#8486](https://github.com/qbittorrent/qBittorrent/issues/8486)).
Every torrent that Sonarr/Radarr upgrades or that you delete leaves a stale
`.torrent` behind forever.

emonoda reads this same directory as its `core.torrents_dir`, but `emupdate` only
*updates* files (it flags missing ones `NOT_IN_CLIENT` and leaves them in place) —
it never prunes. qbit_manage doesn't either: `rem_orphaned` is disabled and its
orphan scan excludes `/data/torrents/.torrents/**`.

So [**qbit-torrent-files-cleaner**](https://github.com/MaksimShakavin/qbit-torrent-files-cleaner)
sits between the export and emonoda: it deletes any `.torrent` in the export dir
whose info hash is no longer present in qBittorrent under the `tv`/`movies`
categories, keeping the append-only feed in sync with the live torrent set. Without
it the directory grows unbounded and emonoda wastes a rutracker lookup on every dead
torrent.

## Manifests

- `app/` — qBittorrent (defines `FinishedTorrentExportDir`)
- `tools/qbit_manage/` — the recheck/tagging CronJob
- `tools/rutracker-pipeline/` — the combined emonoda → handle_unregistered → monitor_completed CronJob
