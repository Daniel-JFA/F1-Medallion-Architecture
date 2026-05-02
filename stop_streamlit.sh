#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${BASE_DIR}/logs"
PID_FILE="${LOG_DIR}/streamlit.pid"
PORT_FILE="${LOG_DIR}/streamlit.port"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "No hay una instancia registrada de F1 Gold Streamlit."
  exit 0
fi

PID="$(cat "${PID_FILE}")"

if kill -0 "${PID}" >/dev/null 2>&1; then
  kill "${PID}"
  echo "Instancia detenida. PID: ${PID}"
else
  echo "La instancia registrada ya no estaba corriendo."
fi

rm -f "${PID_FILE}" "${PORT_FILE}"
