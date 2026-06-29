#!/usr/bin/env bash
set -euo pipefail

# Определяем пути где находятся скрипты
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/example.conf}"

source "$CONFIG_FILE"

msg="${*:-}"
[[ -n "$msg" ]] || exit 0

logger -t acme-cert "$msg"

if [[ -n "${TG_BOT_TOKEN:-}" && -n "${TG_CHAT_ID:-}" ]]; then
  curl -fsS --max-time 10 \
    -X POST "https://api.telegram.org/bot${TG_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TG_CHAT_ID}" \
    --data-urlencode "text=${msg}" \
    >/dev/null || true
fi
