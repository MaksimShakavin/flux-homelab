#!/bin/sh
# Keeps qBittorrent's listen_port in sync with Gluetun's ProtonVPN NAT-PMP
# forwarded port, and recovers a stuck port-forward (sustained port=0) by
# cycling the tunnel through Gluetun's control server. Never restarts the pod.
set -eu

GLUETUN_CONTROL_SERVER="${GLUETUN_CONTROL_SERVER:-http://localhost:8000}"
QBITTORRENT_HOST="${QBITTORRENT_HOST:-localhost}"
QBITTORRENT_WEBUI_PORT="${QBITTORRENT_WEBUI_PORT:-8080}"
QB="http://${QBITTORRENT_HOST}:${QBITTORRENT_WEBUI_PORT}"
INTERVAL="${INTERVAL:-60}"
THRESHOLD="${THRESHOLD:-3}"
SETTLE="${SETTLE:-90}"

log() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) $*"; }

get_pf_port() {
  curl -fsS --max-time 10 -H "X-API-Key: ${GLUETUN_CONTROL_SERVER_API_KEY}" \
    "${GLUETUN_CONTROL_SERVER}/v1/portforward" 2>/dev/null \
    | grep -o '"port":[0-9]*' | grep -o '[0-9]*' || true
}

get_qb_port() {
  curl -fsS --max-time 10 "${QB}/api/v2/app/preferences" 2>/dev/null \
    | grep -o '"listen_port":[0-9]*' | grep -o '[0-9]*' || true
}

set_qb_port() {
  curl -fsS --max-time 10 -X POST "${QB}/api/v2/app/setPreferences" \
    --data-urlencode "json={\"listen_port\":$1,\"random_port\":false}" >/dev/null
}

cycle_tunnel() {
  log "port-forward stuck at 0 for ${THRESHOLD} checks; cycling VPN tunnel"
  curl -fsS --max-time 10 -X PUT -H "X-API-Key: ${GLUETUN_CONTROL_SERVER_API_KEY}" \
    -d '{"status":"stopped"}' "${GLUETUN_CONTROL_SERVER}/v1/vpn/status" >/dev/null || true
  sleep 5
  curl -fsS --max-time 10 -X PUT -H "X-API-Key: ${GLUETUN_CONTROL_SERVER_API_KEY}" \
    -d '{"status":"running"}' "${GLUETUN_CONTROL_SERVER}/v1/vpn/status" >/dev/null || true
  log "tunnel restart requested; settling for ${SETTLE}s"
  sleep "${SETTLE}"
}

log "port-watchdog starting (interval=${INTERVAL}s threshold=${THRESHOLD} settle=${SETTLE}s)"
zeros=0
while true; do
  pf="$(get_pf_port)"
  if [ -z "${pf}" ]; then
    log "no port-forward response from Gluetun yet"
  elif [ "${pf}" = "0" ]; then
    zeros=$((zeros + 1))
    log "forwarded port is 0 (${zeros}/${THRESHOLD})"
    if [ "${zeros}" -ge "${THRESHOLD}" ]; then
      cycle_tunnel
      zeros=0
    fi
  else
    zeros=0
    qb="$(get_qb_port)"
    if [ "${pf}" != "${qb}" ]; then
      if set_qb_port "${pf}"; then
        log "synced qBittorrent listen_port ${qb:-unknown} -> ${pf}"
      else
        log "failed to set qBittorrent listen_port to ${pf}"
      fi
    fi
  fi
  sleep "${INTERVAL}"
done
