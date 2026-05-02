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

FREEZE_LABEL="${1:-}"

run_sql_file() {
  local file_path="$1"
  echo ""
  echo "==> Ejecutando $(basename "${file_path}")"
  "${MYSQL_CMD[@]}" < "${file_path}"
}

echo "Iniciando refresco de capas F1"
echo "Host: ${MYSQL_HOST}:${MYSQL_PORT}"
echo "Usuario: ${MYSQL_USER}"

run_sql_file "${BASE_DIR}/F1_relationships.sql"
run_sql_file "${BASE_DIR}/F1_mysql_silver.sql"
"${MYSQL_CMD[@]}" -e "DROP TABLE IF EXISTS F1_gold.kpi_snapshot_history;"
run_sql_file "${BASE_DIR}/F1_mysql_gold.sql"

if [[ -n "${FREEZE_LABEL}" ]]; then
  echo ""
  echo "==> Congelando KPIs con etiqueta: ${FREEZE_LABEL}"
  MYSQL_HOST="${MYSQL_HOST}" \
  MYSQL_PORT="${MYSQL_PORT}" \
  MYSQL_USER="${MYSQL_USER}" \
  MYSQL_PASSWORD="${MYSQL_PASSWORD}" \
  "${BASE_DIR}/F1_freeze_kpis.sh" "${FREEZE_LABEL}"
fi

echo ""
echo "==> Validacion rapida"
"${MYSQL_CMD[@]}" -D F1 -B -e \
  "SELECT COUNT(*) AS total_fk_f1 FROM information_schema.table_constraints WHERE table_schema='F1' AND constraint_type='FOREIGN KEY';"

"${MYSQL_CMD[@]}" -D F1_silver -B -e \
  "SELECT COUNT(*) AS total_fk_f1_silver FROM information_schema.table_constraints WHERE table_schema='F1_silver' AND constraint_type='FOREIGN KEY';
   SELECT * FROM vw_silver_summary;"

"${MYSQL_CMD[@]}" -D F1_gold -B -e \
  "SELECT COUNT(*) AS total_tables_f1_gold FROM information_schema.tables WHERE table_schema='F1_gold' AND table_type='BASE TABLE';
   SELECT COUNT(*) AS total_views_f1_gold FROM information_schema.views WHERE table_schema='F1_gold';
   SELECT * FROM vw_dashboard_kpi_cards;"

echo ""
echo "Refresco completado correctamente."
