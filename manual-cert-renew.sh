#!/usr/bin/env bash
set -u
set -o pipefail

DOMAIN="your_sub.domain.ru"
LOG="/var/log/certbot-regru-run.log"

if certbot certonly \
  --manual \
  --preferred-challenges dns \
  --manual-auth-hook /usr/local/bin/regru-auth.sh \
  --manual-cleanup-hook /usr/local/bin/regru-cleanup.sh \
  --deploy-hook /usr/local/bin/deploy-success.sh \
  -d "$DOMAIN" \
  >"$LOG" 2>&1
then
  exit 0
else
  rc=$?
  /usr/local/bin/acme-notify.sh "ACME renewal FAILED for ${DOMAIN}. Exit code: ${rc}. Check ${LOG} and /var/log/letsencrypt/letsencrypt.log"
  exit "$rc"
fi
