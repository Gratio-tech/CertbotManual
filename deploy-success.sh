#!/usr/bin/env bash
set -euo pipefail

# Определяем пути где находятся скрипты
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"

domains="${RENEWED_DOMAINS:-unknown}"

systemctl restart dnsmasq
systemctl reload nginx

"${SCRIPT_DIR}/acme-notify.sh" "ACME certificate renewed successfully. Domains: ${domains}. nginx reloaded."
