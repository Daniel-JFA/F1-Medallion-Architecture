#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="${BASE_DIR}/.tools"
LOG_DIR="${BASE_DIR}/logs"
CLOUDFLARED_BIN="${TOOLS_DIR}/cloudflared"
PID_FILE="${LOG_DIR}/cloudflared.pid"
URL_FILE="${LOG_DIR}/cloudflared.url"
LOG_FILE="${LOG_DIR}/cloudflared.log"
TARGET_URL="${TARGET_URL:-http://127.0.0.1:8501}"
CLOUDFLARED_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"

mkdir -p "${TOOLS_DIR}" "${LOG_DIR}"

download_cloudflared() {
  echo "Descargando cloudflared..."
  curl -fsSL "${CLOUDFLARED_URL}" -o "${CLOUDFLARED_BIN}"
  chmod +x "${CLOUDFLARED_BIN}"
}

extract_url() {
  grep -Eo 'https://[-a-zA-Z0-9]+\.trycloudflare\.com' "${LOG_FILE}" | tail -n 1
}

if [[ ! -x "${CLOUDFLARED_BIN}" ]]; then
  download_cloudflared
fi

if [[ -f "${PID_FILE}" ]]; then
  EXISTING_PID="$(cat "${PID_FILE}")"
  if kill -0 "${EXISTING_PID}" >/dev/null 2>&1; then
    if [[ -f "${URL_FILE}" ]]; then
      echo "Túnel público ya está corriendo."
      echo "URL pública: $(cat "${URL_FILE}")"
      echo "Log: ${LOG_FILE}"
      exit 0
    fi
  fi
fi

rm -f "${PID_FILE}" "${URL_FILE}" "${LOG_FILE}"

setsid "${CLOUDFLARED_BIN}" tunnel --no-autoupdate --url "${TARGET_URL}" \
  > "${LOG_FILE}" 2>&1 < /dev/null &

APP_PID=$!
echo "${APP_PID}" > "${PID_FILE}"

for _ in $(seq 1 30); do
  if [[ -f "${LOG_FILE}" ]]; then
    PUBLIC_URL="$(extract_url || true)"
    if [[ -n "${PUBLIC_URL}" ]]; then
      echo "${PUBLIC_URL}" > "${URL_FILE}"
      echo "Túnel público iniciado correctamente."
      echo "URL pública: ${PUBLIC_URL}"
      echo "Destino local: ${TARGET_URL}"
      echo "PID: ${APP_PID}"
      echo "Log: ${LOG_FILE}"
      exit 0
    fi
  fi
  sleep 1
done

echo "No fue posible obtener la URL pública del túnel."
echo "Revisa el log en: ${LOG_FILE}"
exit 1
