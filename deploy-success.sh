#!/usr/bin/env bash
set -euo pipefail

# Определяем пути где находятся скрипты
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/example.conf}"

source "$CONFIG_FILE"

domains="${RENEWED_DOMAINS:-unknown}"

[[ "${DEPLOY_RESTART_DNSMASQ:-false}" == "true" ]] && systemctl restart dnsmasq
[[ "${DEPLOY_RELOAD_NGINX:-true}" == "true" ]] && systemctl reload nginx
"${SCRIPT_DIR}/acme-notify.sh" "ACME certificate renewed successfully. Domains: ${domains}."

"${SCRIPT_DIR}/acme-notify.sh" "ACME certificate renewed successfully. Domains: ${domains}. nginx reloaded."
