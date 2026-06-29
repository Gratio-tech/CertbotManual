#!/usr/bin/env bash
set -u
set -o pipefail

DOMAIN="your_sub.domain.ru"
LOG="/var/log/certbot-regru-run.log"

# Определяем пути где находятся скрипты
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"

CONFIG_FILE="${CERTBOT_MANUAL_CONFIG:-/etc/example.conf}"
source "$CONFIG_FILE"

if certbot certonly \
  --manual \
  --preferred-challenges dns \
  --manual-auth-hook "${SCRIPT_DIR}/regru-auth.sh" \
  --manual-cleanup-hook "${SCRIPT_DIR}/regru-cleanup.sh" \
  --deploy-hook "${SCRIPT_DIR}/deploy-success.sh" \
  -d "$DOMAIN" \
  >"$LOG" 2>&1
then
  exit 0
else
  rc=$?
  "${SCRIPT_DIR}/acme-notify.sh" "ACME renewal FAILED for ${DOMAIN}. Exit code: ${rc}. Check ${LOG} and /var/log/letsencrypt/letsencrypt.log"
  exit "$rc"
fi
