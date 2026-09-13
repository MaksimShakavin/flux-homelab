# qBittorrent + emonoda torrent-file flow

This stack lets the \*arr automations behave in the [rutracker](https://rutracker.org)
world. On rutracker, TV shows are published as season packs — when a new episode
airs, the uploader adds it to the *same* pack and re-creates the torrent. emonoda
catches those re-created torrents and re-uploads them to qBittorrent, keeping the
season pack up to date automatically. qbit-torrent-files-cleaner is the housekeeping half of that
flow (see below).

Three hourly CronJobs cooperate around one directory, qBittorrent's finished-torrent
export dir: `/data/torrents/.torrents/completed` (shared via the NFS `/data` mount).

They run hourly, staggered 5 minutes apart so each finishes before the next starts,
in `Europe/Warsaw` with `concurrencyPolicy: Forbid`:

| Runs               | Cron         | App                        | Role                                                        |
| ------------------ | ------------ | -------------------------- | ---------------------------------------------------------- |
| Every hour, on :00 | `0 * * * *`  | qbit_manage                | Recheck + tagging. Does not touch the export dir.          |
| Every hour, on :05 | `5 * * * *`  | qbit-torrent-files-cleaner | Prunes exported `.torrent` files no longer in the client.  |
| Every hour, on :10 | `10 * * * *` | emonoda                    | `emupdate` refreshes the remaining (live) `.torrent` files. |

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
- `tools/qbit_manage/`, `tools/qbit-torrent-files-cleaner/`, `tools/emonoda/` — the three CronJobs
