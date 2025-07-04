#!/usr/bin/env bash

set -euo pipefail


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# === Logging setup ===
log() {
  local timestamp
  timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
  local message="[$timestamp] $*"
  logger -t update_porkbun "$message"
  echo "$message"
}

# === Check for required tools ===
if ! command -v jq >/dev/null 2>&1; then
  log "[ERROR] 'jq' is not installed. Please install jq to continue."
  exit 1
fi

# === Load config ===
if [[ -f .env ]]; then
  source .env
else
  log "[ERROR] Missing .env file in $SCRIPT_DIR. Please create one."
  exit 1
fi


: "${API_KEY:?API_KEY is required}"
: "${API_SECRET:?API_SECRET is required}"
: "${DOMAIN:?DOMAIN is required}"
: "${RECORD_NAME:?RECORD_NAME is required}"
: "${TTL:=300}"

# === API base URL ===
API_BASE_URL="https://api.porkbun.com/api/json/v3"

# === Detect IPs ===
IPV4=$(curl -s --max-time 5 https://api.ipify.org || true)
IPV6=$(curl -s --max-time 5 https://api6.ipify.org || true)


# === Update records ===
update_record() {
  local TYPE=$1
  local IP=$2

  log "Processing $TYPE record for $RECORD_NAME.$DOMAIN → $IP"

  # Retrieve existing record
  RESPONSE=$(curl -s -X POST "$API_BASE_URL/dns/retrieveByNameType/$DOMAIN/$TYPE/$RECORD_NAME" \
    -H "Content-Type: application/json" \
    -d '{
      "apikey": "'"$API_KEY"'",
      "secretapikey": "'"$API_SECRET"'"
    }')
  log "Raw retrieve response: $RESPONSE"

  RECORD_ID=$(echo "$RESPONSE" | jq -r '.records[0].id // empty')
  EXISTING_IP=$(echo "$RESPONSE" | jq -r '.records[0].content // empty')

  if [[ "$EXISTING_IP" == "$IP" ]]; then
    log "$TYPE record is already up-to-date ($IP), skipping."
    return
  fi

  if [[ -n "$RECORD_ID" ]]; then
    log "Updating existing $TYPE record (ID=$RECORD_ID)"
    RESPONSE=$(curl -s -X POST "$API_BASE_URL/dns/edit/$DOMAIN/$RECORD_ID" \
      -H "Content-Type: application/json" \
      -d '{
        "apikey": "'"$API_KEY"'",
        "secretapikey": "'"$API_SECRET"'",
        "type": "'"$TYPE"'",
        "name": "'"$RECORD_NAME"'",
        "content": "'"$IP"'",
        "ttl": '"$TTL"'
      }')
  else
    log "Creating new $TYPE record"
    RESPONSE=$(curl -s -X POST "$API_BASE_URL/dns/create/$DOMAIN" \
      -H "Content-Type: application/json" \
      -d '{
        "apikey": "'"$API_KEY"'",
        "secretapikey": "'"$API_SECRET"'",
        "type": "'"$TYPE"'",
        "name": "'"$RECORD_NAME"'",
        "content": "'"$IP"'",
        "ttl": '"$TTL"'
      }')
  fi

  log "Porkbun API response: $(echo "$RESPONSE" | jq -c '.')"
}

if [[ -n "$IPV4" ]]; then
  update_record "A" "$IPV4"
else
  log "No external IPv4 detected."
fi

if [[ -n "$IPV6" ]]; then
  update_record "AAAA" "$IPV6"
else
  log "No external IPv6 detected."
fi
