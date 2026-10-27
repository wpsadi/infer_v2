#!/usr/bin/env bash
# Creates (or updates) the WAF deny rule that only let requests through to the
# function when the x-functions-token header equals APPWRITE_FUNCTIONS_TOKEN.
#
# Required env vars: APPWRITE_ENDPOINT, APPWRITE_PROJECT_ID, APPWRITE_API_KEY,
#                    APPWRITE_FUNCTIONS_TOKEN, FUNCTION_ID

set -euo pipefail

for var in APPWRITE_ENDPOINT APPWRITE_PROJECT_ID APPWRITE_API_KEY APPWRITE_FUNCTIONS_TOKEN FUNCTION_ID; do
  [ -n "${!var:-}" ] || { echo "Missing required env var: $var" >&2; exit 1; }
done

HEADER="headers.x-functions-token"

upsert_rule() {
  local rule_id=$1 name=$2 conditions=$3 body status
  body=$(jq -n \
    --arg id "$rule_id" --arg name "$name" --arg fn "$FUNCTION_ID" \
    --argjson conditions "$conditions" \
    '{ruleId: $id, name: $name, resourceType: "functions", resourceId: $fn,
      priority: 100, enabled: true, conditions: $conditions}')

  call() {
    curl -sS -o /tmp/waf-response.json -w '%{http_code}' -X "$1" "$2" \
      -H "Content-Type: application/json" \
      -H "X-Appwrite-Project: $APPWRITE_PROJECT_ID" \
      -H "X-Appwrite-Key: $APPWRITE_API_KEY" \
      -d "$body"
  }

  status=$(call POST "$APPWRITE_ENDPOINT/waf/rules/deny")
  if [ "$status" = "409" ]; then
    status=$(call PUT "$APPWRITE_ENDPOINT/waf/rules/deny/$rule_id")
  fi
  if [[ "$status" != 2* ]]; then
    echo "Failed to apply rule $rule_id (HTTP $status):" >&2
    cat /tmp/waf-response.json >&2
    exit 1
  fi
  echo "Applied WAF rule $rule_id"
}

# One deny rule: matches (and blocks) any request whose header is not exactly the token,
# which includes requests where the header is missing
upsert_rule "inference-deny-bad-token" "inference: require functions token" \
  "$(jq -n --arg h "$HEADER" --arg t "$APPWRITE_FUNCTIONS_TOKEN" \
    '[{method: "notEqual", attribute: $h, values: [$t]}]')"
