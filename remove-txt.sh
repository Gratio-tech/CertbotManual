#!/usr/bin/env bash
set -euo pipefail

# Определяем пути где находятся скрипты
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd -- "$(dirname -- "$SCRIPT_PATH")" && pwd -P)"
CONFIG_FILE="${SCRIPT_DIR}/example.conf}"

source "$CONFIG_FILE"

SUBDOMAIN="${1:?Usage: $0 _acme-challenge.git}"

# В subdomain следует писать ваш домен для которого нужно очистить TXT-записи с поддоменом _acme-challenge.
# пример запуска для удаления TXT на _acme-challenge.git это ./remove-txt.sh _acme-challenge.git

input_data="$(
  jq -nc \
    --arg username "$REGRU_USER" \
    --arg password "$REGRU_PASS" \
    --arg domain "$REGRU_ZONE" \
    --arg subdomain "$SUBDOMAIN" \
    '{
      username: $username,
      password: $password,
      domains: [{dname: $domain}],
      subdomain: $subdomain,
      record_type: "TXT",
      output_content_type: "plain"
    }'
)"

curl -fsS https://api.reg.ru/api/regru2/zone/remove_record \
  -d "input_format=json" \
  --data-urlencode "input_data=${input_data}" \
  -d "output_format=json" \
  -d "output_content_type=plain" | jq
