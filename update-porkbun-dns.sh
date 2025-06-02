#!/usr/bin/env bash

set -euo pipefail

# Load environment variables
source .env

API_URL="https://porkbun.com/api/json/v3"
AUTH_HEADER="Authorization: Bearer $API_KEY:$API_SECRET"

function api_call() {
  local method=$1
  local endpoint=$2
  local data=${3:-}

  if [[ "$method" == "GET" ]]; then
    response=$(curl -sSL -H "Content-Type: application/json" -H "$AUTH_HEADER" "$API_URL$endpoint") || {
      echo "Error: Network error calling GET $endpoint"
      exit 1
    }
  else
    response=$(curl -sSL -X "$method" -H "Content-Type: application/json" -H "$AUTH_HEADER" -d "$data" "$API_URL$endpoint") || {
      echo "Error: Network error calling $method $endpoint"
      exit 1
    }
  fi

  # Check if response is valid JSON
  if ! echo "$response" | jq empty >/dev/null 2>&1; then
    echo "Error: Invalid JSON response from API endpoint $endpoint"
    echo "Response was:"
    echo "$response"
    exit 1
  fi

  echo "$response"
}

function get_record() {
  local record_type=$1
  local domain=$2
  local name=$3

  api_call GET "/dns/retrieveByNameType/$domain/$record_type/$name"
}

function update_record() {
  local domain=$1
  local record_id=$2
  local name=$3
  local type=$4
  local content=$5
  local ttl=${6:-300}

  local payload=$(jq -n \
    --arg name "$name" \
    --arg type "$type" \
    --arg content "$content" \
    --argjson ttl "$ttl" \
    '{name: $name, type: $type, content: $content, ttl: $ttl}')

  api_call POST "/dns/editById/$domain/$record_id" "$payload"
}

function create_record() {
  local domain=$1
  local name=$2
  local type=$3
  local content=$4
  local ttl=${5:-300}

  local payload=$(jq -n \
    --arg name "$name" \
    --arg type "$type" \
    --arg content "$content" \
    --argjson ttl "$ttl" \
    '{name: $name, type: $type, content: $content, ttl: $ttl}')

  api_call POST "/dns/create/$domain" "$payload"
}

# Detect current IPv4 and IPv6 addresses if not set
ip4=${IPV4:-$(curl -s https://api.ipify.org || echo "")}
ip6=${IPV6:-$(curl -s https://api6.ipify.org || echo "")}

if [[ -z "$ip4" && -z "$ip6" ]]; then
  echo "Error: No IPv4 or IPv6 address detected."
  exit 1
fi

# Update or create A record if IPv4 detected
if [[ -n "$ip4" ]]; then
  record_type="A"
  echo "Processing $record_type record for $RECORD_NAME.$DOMAIN with IP $ip4"
  response=$(get_record "$record_type" "$DOMAIN" "$RECORD_NAME")
  record_id=$(echo "$response" | jq -r '.records[0].id // empty')

  if [[ -n "$record_id" ]]; then
    echo "Record exists. Updating record ID $record_id"
    update_record "$DOMAIN" "$record_id" "$RECORD_NAME" "$record_type" "$ip4" "$TTL"
  else
    echo "Record not found. Creating new record"
    create_record "$DOMAIN" "$RECORD_NAME" "$record_type" "$ip4" "$TTL"
  fi
fi

# Update or create AAAA record if IPv6 detected
if [[ -n "$ip6" ]]; then
  record_type="AAAA"
  echo "Processing $record_type record for $RECORD_NAME.$DOMAIN with IP $ip6"
  response=$(get_record "$record_type" "$DOMAIN" "$RECORD_NAME")
  record_id=$(echo "$response" | jq -r '.records[0].id // empty')

  if [[ -n "$record_id" ]]; then
    echo "Record exists. Updating record ID $record_id"
    update_record "$DOMAIN" "$record_id" "$RECORD_NAME" "$record_type" "$ip6" "$TTL"
  else
    echo "Record not found. Creating new record"
    create_record "$DOMAIN" "$RECORD_NAME" "$record_type" "$ip6" "$TTL"
  fi
fi

echo "DNS update completed successfully."
