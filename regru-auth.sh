#!/usr/bin/env bash
set -euo pipefail

source /etc/example.conf

LOG=/var/log/certbot-regru-hook.log

log() {
  printf '%s %s\n' "$(date -Is)" "$*" | tee -a "$LOG" >&2
}

fail() {
  log "ERROR: $*"
  /usr/local/bin/acme-notify.sh "ACME DNS auth failed for ${CERTBOT_IDENTIFIER:-${CERTBOT_DOMAIN:-unknown}}: $*" || true
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need curl
need jq
need dig
need grep
need sed

identifier="${CERTBOT_IDENTIFIER:-${CERTBOT_DOMAIN:-}}"
validation="${CERTBOT_VALIDATION:-}"

[[ -n "$identifier" ]] || fail "CERTBOT_IDENTIFIER/CERTBOT_DOMAIN is empty"
[[ -n "$validation" ]] || fail "CERTBOT_VALIDATION is empty"
[[ -n "${REGRU_USER:-}" ]] || fail "REGRU_USER is empty"
[[ -n "${REGRU_PASS:-}" ]] || fail "REGRU_PASS is empty"
[[ -n "${REGRU_ZONE:-}" ]] || fail "REGRU_ZONE is empty"

# Для wildcard *.example.com challenge ставится на _acme-challenge.example.com
if [[ "$identifier" == \*.* ]]; then
  identifier="${identifier#*.}"
fi

zone="$REGRU_ZONE"
fqdn="_acme-challenge.${identifier}"

if [[ "$fqdn" == "$zone" ]]; then
  subdomain="@"
else
  suffix=".${zone}"
  [[ "$fqdn" == *"$suffix" ]] || fail "challenge fqdn ${fqdn} is not inside REGRU_ZONE=${zone}"
  subdomain="${fqdn%$suffix}"
fi

api() {
  local endpoint="$1"
  local input_data

  case "$endpoint" in
    zone/add_txt)
      input_data="$(
        jq -nc \
          --arg username "$REGRU_USER" \
          --arg password "$REGRU_PASS" \
          --arg domain "$zone" \
          --arg subdomain "$subdomain" \
          --arg text "$validation" \
          '{
            username: $username,
            password: $password,
            domains: [{dname: $domain}],
            subdomain: $subdomain,
            text: $text,
            output_content_type: "plain"
          }'
      )"
      ;;

    *)
      fail "Unsupported REG.RU endpoint: $endpoint"
      ;;
  esac

  local resp
  resp="$(
    curl -fsS --max-time 30 "https://api.reg.ru/api/regru2/${endpoint}" \
      -d "input_format=json" \
      --data-urlencode "input_data=${input_data}" \
      -d "output_format=json" \
      -d "output_content_type=plain"
  )" || return 1

  log "REG.RU ${endpoint}: ${resp}"

  jq -e '.result == "success" and (.answer.domains[0].result == "success")' <<<"$resp" >/dev/null
}

has_txt_on_ns() {
  local ns="$1"

  dig +time=3 +tries=1 +short TXT "$fqdn" @"$ns" \
    | tr -d '"' \
    | grep -Fxq "$validation"
}

log "Adding TXT ${subdomain}.${zone} = ${validation}"

api zone/add_txt \
  -d "subdomain=${subdomain}" \
  --data-urlencode "text=${validation}" \
  || fail "REG.RU zone/add_txt failed"

mapfile -t ns_list < <(dig +short NS "$zone" | sed 's/\.$//')
((${#ns_list[@]} > 0)) || fail "No authoritative NS returned for ${zone}"

deadline=$((SECONDS + ${ACME_PROPAGATION_TIMEOUT:-1800}))

while (( SECONDS < deadline )); do
  ok=1

  for ns in "${ns_list[@]}"; do
    if ! has_txt_on_ns "$ns"; then
      ok=0
      break
    fi
  done

  if (( ok )); then
    for resolver in 1.1.1.1 8.8.8.8; do
      if ! dig +time=3 +tries=1 +short TXT "$fqdn" @"$resolver" \
        | tr -d '"' \
        | grep -Fq "$validation"; then
        ok=0
        break
      fi
    done
  fi

  if (( ok )); then
    log "TXT propagated on authoritative NS for ${fqdn}"
    exit 0
  fi

  log "Waiting TXT propagation for ${fqdn}; current @1.1.1.1 answer: $(dig +short TXT "$fqdn" @1.1.1.1 || true)"
  sleep "${ACME_PROPAGATION_INTERVAL:-15}"
done

fail "TXT was not visible on authoritative NS within timeout for ${fqdn}"
