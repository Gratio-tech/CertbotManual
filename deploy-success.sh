#!/usr/bin/env bash
set -euo pipefail

domains="${RENEWED_DOMAINS:-unknown}"

systemctl restart dnsmasq
systemctl reload nginx

/usr/local/bin/acme-notify.sh "ACME certificate renewed successfully. Domains: ${domains}. nginx reloaded."
