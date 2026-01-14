#!/usr/bin/env bash

ES_URL="${ES_URL:-http://localhost:9200}"

declare -A RULES=(
  [100002]="API, Login Success"
  [100003]="API, Login Failed"
  [100004]="API, Brute Force"
  [100005]="API, SQL Injection"
  [100006]="API, Internal Error"
  [100101]="Suricata, ICMP detected"
  [100102]="Suricata, Possible API Abuse"
  [100103]="Suricata, SQLi"
  [100104]="Suricata, User-Agent"
  [100105]="Suricata, corr+500"
  [100106]="Suricata, multiple"
  [100107]="Suricata, same-src"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

for id in "${!RULES[@]}"; do
  name="${RULES[$id]}"
  printf "%s %s: " "$id" "$name"

  COUNT=$(curl -s "${ES_URL}/soc-logs-*/_search?q=rule.id:${id}" \
    | jq '.hits.total.value // 0')

  if [ "$COUNT" -gt 0 ]; then
    printf "${GREEN}Verified (%s alerts)${NC}\n" "$COUNT"
  else
    printf "${RED}Not Triggered${NC}\n"
  fi
done
