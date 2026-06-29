#!/usr/bin/env bash
set -euo pipefail

source /etc/example.conf

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
