#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${BASE_DIR}/app.py"
LOG_DIR="${BASE_DIR}/logs"
PID_FILE="${LOG_DIR}/streamlit.pid"
PORT_FILE="${LOG_DIR}/streamlit.port"
LOG_FILE="${LOG_DIR}/streamlit.log"

mkdir -p "${LOG_DIR}"

export STREAMLIT_BROWSER_GATHER_USAGE_STATS=false
export STREAMLIT_SERVER_HEADLESS=true

if [[ -x "${BASE_DIR}/.venv/bin/streamlit" ]]; then
  STREAMLIT_BIN="${BASE_DIR}/.venv/bin/streamlit"
else
  STREAMLIT_BIN="streamlit"
fi

DEFAULT_PORT="${STREAMLIT_PORT:-8501}"

get_lan_ip() {
  ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1; i<=NF; i++) if ($i=="src") print $(i+1)}' | head -n 1
}

is_port_listening() {
  local port="$1"
  ss -ltn | awk '{print $4}' | grep -Eq "[:.]${port}$"
}

print_running_message() {
  local port="$1"
  local local_url="http://127.0.0.1:${port}"
  local lan_ip
  lan_ip="$(get_lan_ip || true)"
  echo "F1 Gold Streamlit ya está corriendo."
  echo "URL local: ${local_url}"
  if [[ -n "${lan_ip}" ]]; then
    echo "URL red local: http://${lan_ip}:${port}"
  fi
  echo "Log: ${LOG_FILE}"
}

maybe_open_browser() {
  local url="$1"
  if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "${url}" >/dev/null 2>&1 || true
  fi
}

if [[ -f "${PID_FILE}" && -f "${PORT_FILE}" ]]; then
  EXISTING_PID="$(cat "${PID_FILE}")"
  EXISTING_PORT="$(cat "${PORT_FILE}")"
  if kill -0 "${EXISTING_PID}" >/dev/null 2>&1 && curl -fsS "http://127.0.0.1:${EXISTING_PORT}" >/dev/null 2>&1; then
    print_running_message "${EXISTING_PORT}"
    maybe_open_browser "http://127.0.0.1:${EXISTING_PORT}"
    exit 0
  fi
fi

rm -f "${PID_FILE}" "${PORT_FILE}"

PORT="${DEFAULT_PORT}"
while is_port_listening "${PORT}"; do
  PORT="$((PORT + 1))"
done

setsid "${STREAMLIT_BIN}" run "${APP_PATH}" \
  --server.headless true \
  --server.address 0.0.0.0 \
  --server.port "${PORT}" \
  --browser.gatherUsageStats false \
  > "${LOG_FILE}" 2>&1 < /dev/null &

APP_PID=$!
echo "${APP_PID}" > "${PID_FILE}"
echo "${PORT}" > "${PORT_FILE}"

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}" >/dev/null 2>&1; then
    URL="http://127.0.0.1:${PORT}"
    LAN_IP="$(get_lan_ip || true)"
    echo "F1 Gold Streamlit iniciado correctamente."
    echo "URL local: ${URL}"
    if [[ -n "${LAN_IP}" ]]; then
      echo "URL red local: http://${LAN_IP}:${PORT}"
    fi
    echo "PID: ${APP_PID}"
    echo "Log: ${LOG_FILE}"
    maybe_open_browser "${URL}"
    exit 0
  fi
  sleep 1
done

echo "No fue posible iniciar Streamlit correctamente."
echo "Revisa el log en: ${LOG_FILE}"
exit 1
