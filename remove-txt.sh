#!/usr/bin/env bash
set -euo pipefail

source /etc/example.conf

# В subdomain следует писать ваш домен для которого нужно очистить TXT-записи с поддоменом _acme-challenge.
# в примере ниже это git, то есть полный домен выглядит примерно так: _acme-challenge.git.your-domen.com

input_data="$(
  jq -nc \
    --arg username "$REGRU_USER" \
    --arg password "$REGRU_PASS" \
    --arg domain "$REGRU_ZONE" \
    --arg subdomain "_acme-challenge.git" \
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
