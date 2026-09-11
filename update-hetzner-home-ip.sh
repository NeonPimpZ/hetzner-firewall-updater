#!/bin/bash
set -euo pipefail

API_TOKEN="${API_TOKEN:?API_TOKEN not set}"
FIREWALL_NAME="${FIREWALL_NAME:?FIREWALL_NAME not set}"
RULE_DESCRIPTION="${RULE_DESCRIPTION:?RULE_DESCRIPTION not set}"

CURRENT_IP=$(curl -s https://api4.ipify.org)
if [[ -z "$CURRENT_IP" ]]; then
  echo "$(date): Failed to get public IP" >&2
  exit 1
fi

FIREWALL_DATA=$(curl -s \
  -H "Authorization: Bearer $API_TOKEN" \
  "https://api.hetzner.cloud/v1/firewalls?name=$FIREWALL_NAME")

FIREWALL_ID=$(echo "$FIREWALL_DATA" | jq -r '.firewalls[0].id')
if [[ "$FIREWALL_ID" == "null" || -z "$FIREWALL_ID" ]]; then
  echo "$(date): Firewall '$FIREWALL_NAME' not found" >&2
  exit 1
fi

CURRENT_RULES=$(echo "$FIREWALL_DATA" | jq '.firewalls[0].rules')

EXISTING_IP=$(echo "$CURRENT_RULES" | \
  jq -r --arg desc "$RULE_DESCRIPTION" \
  '.[] | select(.description == $desc) | .source_ips[0]' | cut -d/ -f1)

if [[ "$EXISTING_IP" == "$CURRENT_IP" ]]; then
  echo "$(date): IP unchanged ($CURRENT_IP), nothing to do."
  exit 0
fi

echo "$(date): Updating firewall: $EXISTING_IP → $CURRENT_IP"

NEW_RULES=$(echo "$CURRENT_RULES" | jq \
  --arg desc "$RULE_DESCRIPTION" \
  --arg ip "$CURRENT_IP/32" \
  'map(if .description == $desc then .source_ips = [$ip] else . end)')

curl -s -X POST \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"rules\": $NEW_RULES}" \
  "https://api.hetzner.cloud/v1/firewalls/$FIREWALL_ID/actions/set_rules" \
  | jq '.actions[].status'
