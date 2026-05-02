#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${BASE_DIR}/logs"
PID_FILE="${LOG_DIR}/cloudflared.pid"
URL_FILE="${LOG_DIR}/cloudflared.url"

if [[ ! -f "${PID_FILE}" ]]; then
  echo "No hay un túnel público registrado."
  exit 0
fi

PID="$(cat "${PID_FILE}")"

if kill -0 "${PID}" >/dev/null 2>&1; then
  kill "${PID}"
  echo "Túnel público detenido. PID: ${PID}"
else
  echo "El túnel registrado ya no estaba corriendo."
fi

rm -f "${PID_FILE}" "${URL_FILE}"
