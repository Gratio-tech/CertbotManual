#!/usr/bin/env bash
set -euo pipefail

source /etc/example.conf

LOG=/var/log/certbot-regru-hook.log

log() {
  printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG" >&2
}

identifier="${CERTBOT_IDENTIFIER:-${CERTBOT_DOMAIN:-}}"
validation="${CERTBOT_VALIDATION:-}"

if [[ -z "$identifier" || -z "$validation" ]]; then
  log "cleanup skipped: CERTBOT_IDENTIFIER/CERTBOT_DOMAIN or CERTBOT_VALIDATION is empty"
  exit 0
fi

if [[ "$identifier" == \*.* ]]; then
  identifier="${identifier#*.}"
fi

zone="${REGRU_ZONE:?REGRU_ZONE is empty}"
fqdn="_acme-challenge.${identifier}"

if [[ "$fqdn" == "$zone" ]]; then
  subdomain="@"
else
  suffix=".${zone}"
  if [[ "$fqdn" != *"$suffix" ]]; then
    log "cleanup skipped: challenge fqdn ${fqdn} is not inside REGRU_ZONE=${zone}"
    exit 0
  fi
  subdomain="${fqdn%$suffix}"
fi

input_data="$(
  jq -nc \
    --arg username "$REGRU_USER" \
    --arg password "$REGRU_PASS" \
    --arg domain "$zone" \
    --arg subdomain "$subdomain" \
    --arg content "$validation" \
    '{
      username: $username,
      password: $password,
      domains: [{dname: $domain}],
      subdomain: $subdomain,
      record_type: "TXT",
      content: $content,
      output_content_type: "plain"
    }'
)"

resp="$(
  curl -fsS --max-time 30 "https://api.reg.ru/api/regru2/zone/remove_record" \
    -d "input_format=json" \
    --data-urlencode "input_data=${input_data}" \
    -d "output_format=json" \
    -d "output_content_type=plain"
)" || {
  log "WARN: REG.RU remove_record curl failed for ${subdomain}.${zone}"
  /usr/local/bin/acme-notify.sh "ACME cleanup failed for ${fqdn}: curl failed" || true
  exit 0
}

log "REG.RU zone/remove_record: ${resp}"

if ! jq -e '.result == "success" and (.answer.domains[0].result == "success")' <<<"$resp" >/dev/null; then
  log "WARN: REG.RU remove_record returned non-success for ${subdomain}.${zone}"
  /usr/local/bin/acme-notify.sh "ACME cleanup failed for ${fqdn}: REG.RU returned non-success" || true
fi

exit 0
