#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MYSQL_HOST="${MYSQL_HOST:-127.0.0.1}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-root}"

MYSQL_CMD=(
  mysql
  --ssl=0
  -h "${MYSQL_HOST}"
  -P "${MYSQL_PORT}"
  -u"${MYSQL_USER}"
  -p"${MYSQL_PASSWORD}"
)

RAW_LABEL="${1:-}"

if [[ -n "${RAW_LABEL}" ]]; then
  SNAPSHOT_LABEL="${RAW_LABEL}"
else
  SNAPSHOT_LABEL="clase_$(date +%Y_%m_%d_%H%M%S)"
fi

SAFE_LABEL="${SNAPSHOT_LABEL//\'/\'\'}"
TMP_SQL="$(mktemp)"
trap 'rm -f "${TMP_SQL}"' EXIT

echo "Congelando KPIs de F1_gold"
echo "Host: ${MYSQL_HOST}:${MYSQL_PORT}"
echo "Usuario: ${MYSQL_USER}"
echo "Etiqueta: ${SNAPSHOT_LABEL}"

{
  printf "SET @snapshot_label = '%s';\n" "${SAFE_LABEL}"
  cat "${BASE_DIR}/F1_gold_kpi_history.sql"
} > "${TMP_SQL}"

"${MYSQL_CMD[@]}" < "${TMP_SQL}"

echo ""
echo "==> Validacion del snapshot"
"${MYSQL_CMD[@]}" -D F1_control -B -e \
  "SELECT snapshot_label, source_schema, COUNT(*) AS frozen_kpis, MIN(snapshot_taken_at) AS snapshot_taken_at
   FROM f1_gold_kpi_snapshot_history
   WHERE snapshot_label COLLATE utf8mb4_general_ci = '${SAFE_LABEL}'
   GROUP BY snapshot_label, source_schema;"

echo ""
echo "Congelamiento completado correctamente."
