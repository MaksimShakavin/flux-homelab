#!/usr/bin/env bash
# cnpg-migrate-data.sh — Stage 2 of the Crunchy→CNPG per-app cutover.
#
# Scales the app to 0, logical-dumps its database from the still-running Crunchy
# primary, restores it into the (empty, already-bootstrapped) CNPG cluster, and
# prints a source-vs-target verification (table count + per-table row counts).
#
# It NEVER writes to Crunchy (dump is read-only) and NEVER touches manifests —
# the Flux/manifest stages (1, 3, 4) are done by hand/agent around this script.
#
# Usage:
#   scripts/cnpg-migrate-data.sh <app> [app_namespace]
#
#   app_namespace defaults to "default" (authentik uses "security").
#
# Prereqs (Stage 1 already applied & healthy):
#   - CNPG cluster  postgres-<app>   Ready 3/3 in namespace "database"
#   - Mirror secret postgres-<app>-app present in <app_namespace>
#   - Crunchy secret <app>-pguser-<app> present in <app_namespace>
#   - KUBECONFIG exported
set -euo pipefail

APP="${1:?usage: cnpg-migrate-data.sh <app> [app_namespace]}"
APP_NS="${2:-default}"
DB_NS="database"
DEPLOY_KIND="${DEPLOY_KIND:-deploy}"          # some apps may be a different workload kind
DEPLOY_NAME="${DEPLOY_NAME:-$APP}"
SRC_SVC="${APP}-primary.${APP_NS}.svc"        # Crunchy primary (NOT pgbouncer)
DST_SVC="postgres-${APP}-rw.${DB_NS}.svc"     # CNPG rw
SRC_SECRET="${APP}-pguser-${APP}"
DST_SECRET="postgres-${APP}-app"
DBNAME="${DBNAME:-$APP}"
DBUSER="${DBUSER:-$APP}"
MIGRATE_POD="pg-migrate-${APP}"

echo "== cnpg-migrate-data: app=${APP} ns=${APP_NS} =="
echo "   src: ${SRC_SVC} (secret ${SRC_SECRET})"
echo "   dst: ${DST_SVC} (secret ${DST_SECRET})"

# --- preflight -------------------------------------------------------------
kubectl get cluster.postgresql.cnpg.io -n "${DB_NS}" "postgres-${APP}" >/dev/null
ready=$(kubectl get cluster.postgresql.cnpg.io -n "${DB_NS}" "postgres-${APP}" -o jsonpath='{.status.readyInstances}')
[ "${ready}" = "3" ] || { echo "ABORT: CNPG postgres-${APP} not 3/3 ready (got '${ready}')"; exit 1; }
kubectl get secret -n "${APP_NS}" "${DST_SECRET}" >/dev/null || { echo "ABORT: mirror secret ${DST_SECRET} missing in ${APP_NS}"; exit 1; }
kubectl get secret -n "${APP_NS}" "${SRC_SECRET}" >/dev/null || { echo "ABORT: crunchy secret ${SRC_SECRET} missing in ${APP_NS}"; exit 1; }

SRC_PW=$(kubectl get secret -n "${APP_NS}" "${SRC_SECRET}" -o jsonpath='{.data.password}' | base64 -d)
DST_PW=$(kubectl get secret -n "${APP_NS}" "${DST_SECRET}" -o jsonpath='{.data.password}' | base64 -d)

# --- stop writes -----------------------------------------------------------
echo "== scaling ${DEPLOY_KIND}/${DEPLOY_NAME} to 0 =="
kubectl scale "${DEPLOY_KIND}/${DEPLOY_NAME}" -n "${APP_NS}" --replicas 0
kubectl wait --for=delete pod -n "${APP_NS}" -l "app.kubernetes.io/name=${APP}" --timeout=90s 2>/dev/null || true

# --- dump | restore (in-cluster) ------------------------------------------
# Runs in an ephemeral postgres:17 pod in the database ns so both endpoints are
# reachable and no data crosses the laptop. The pgbouncer-schema ACL errors from
# Crunchy dumps ("role _crunchypgbouncer does not exist") are EXPECTED & harmless.
echo "== dump ${SRC_SVC} | restore ${DST_SVC} =="
kubectl run "${MIGRATE_POD}" -n "${DB_NS}" --rm -i --restart=Never --image=postgres:17 \
  --env="SRC_PW=${SRC_PW}" --env="DST_PW=${DST_PW}" \
  --command -- bash -c '
    set -o pipefail
    PGPASSWORD="$SRC_PW" pg_dump -Fc -h '"${SRC_SVC}"' -U '"${DBUSER}"' -d '"${DBNAME}"' \
      | PGPASSWORD="$DST_PW" pg_restore --no-owner --role='"${DBUSER}"' \
          -h '"${DST_SVC}"' -U '"${DBUSER}"' -d '"${DBNAME}"' 2>&1
    echo "restore-pipe-exit=$?"
  ' | grep -vE '_crunchypgbouncer|SCHEMA pgbouncer|FUNCTION get_auth|GRANT USAGE ON SCHEMA pgbouncer|REVOKE ALL ON FUNCTION|errors ignored on restore|recorded in container logs|command prompt|pressing enter' || true

# --- verify ----------------------------------------------------------------
# Emits per-table EXACT row counts for both DBs; diff must be empty. The SQL is
# fed on STDIN to `psql -f -`, so no SQL text is nested inside the shell command
# (this is what previously broke with \x27-style escaping). query_to_xml gets an
# exact count(*) per table without a dynamic-SQL loop.
echo "== verify (source vs target) =="
VERIFY_POD="pg-verify-${APP}"
tmp_src=$(mktemp); tmp_dst=$(mktemp)
VERIFY_SQL='
SELECT schemaname||E'"'"'.'"'"'||relname||E'"'"'='"'"'||
       (xpath(
          E'"'"'/row/c/text()'"'"',
          query_to_xml(
            format(E'"'"'select count(*) c from %I.%I'"'"', schemaname, relname),
            false, true, E'"'"''"'"')
       ))[1]::text::bigint
FROM pg_stat_user_tables
ORDER BY 1;'
run_psql() { # host pw
  printf '%s\n' "${VERIFY_SQL}" | kubectl run "${VERIFY_POD}" -n "${DB_NS}" --rm -i --restart=Never --image=postgres:17 \
    --env="PW=$2" --env="H=$1" --env="U=${DBUSER}" --env="D=${DBNAME}" \
    --command -- bash -c 'PGPASSWORD="$PW" psql -h "$H" -U "$U" -d "$D" -qtA -f -' \
    2>/dev/null | grep -vE 'recorded in container logs|command prompt|pressing enter'
}
run_psql "${SRC_SVC}" "${SRC_PW}" | sort > "${tmp_src}"
run_psql "${DST_SVC}" "${DST_PW}" | sort > "${tmp_dst}"

echo "-- source tables: $(wc -l < ${tmp_src}) / target tables: $(wc -l < ${tmp_dst})"
if diff -u "${tmp_src}" "${tmp_dst}" > /tmp/cnpg-verify-${APP}.diff; then
  echo "VERIFY OK: source and target row counts identical"
else
  echo "VERIFY DIFF (source < , target > ) — review /tmp/cnpg-verify-${APP}.diff:"
  cat /tmp/cnpg-verify-${APP}.diff
fi
rm -f "${tmp_src}" "${tmp_dst}"

echo "== data stage complete. App is still at replicas 0."
echo "   Next: Stage 3 (repoint HR to CNPG, commit) then 'flux reconcile helmrelease ${APP} -n ${APP_NS}' to bring it back up."
