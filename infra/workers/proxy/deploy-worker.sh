#!/usr/bin/env bash
# Upload (or re-upload) the shared foc-gateway-proxy Worker and sync its secrets.
#
# Run this once initially, and again whenever worker.js or the secret set changes.
# Per-site CID updates do NOT require re-running this - they go via KV.
#
# Required env:
#   CLOUDFLARE_API_TOKEN          — FOC account, Workers Scripts Edit
#
# Secrets set on the Worker (only if these env vars are present in the caller):
#   FILBEAM_ACCOUNT_ID            — filbeam's CF account id (D1 owner)
#   FILBEAM_D1_TOKEN              — token scoped to filbeam D1 Read
#   D1_MAINNET                    — filcdn-mainnet-db uuid
#   D1_CALIBRATION                — filcdn-calibration-db uuid

set -euo pipefail

: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN env var required}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"
[[ -f "$CONFIG" ]] || { echo "missing $CONFIG" >&2; exit 1; }

CF_ACCOUNT_ID=$(jq -er .cf_account_id "$CONFIG")
WORKER_SCRIPT=$(jq -er .worker_script "$CONFIG")
KV_ID=$(jq -er .kv_namespace_id "$CONFIG")
COMPAT_DATE=$(jq -er .compatibility_date "$CONFIG")

METADATA=$(jq -n \
  --arg cd "$COMPAT_DATE" \
  --arg kv "$KV_ID" \
  '{
    main_module: "worker.js",
    compatibility_date: $cd,
    bindings: [{ type: "kv_namespace", name: "CIDS", namespace_id: $kv }]
  }')

echo "Uploading $WORKER_SCRIPT ..."
RESP=$(curl -sS -X PUT \
  -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$WORKER_SCRIPT" \
  -F "metadata=$METADATA;type=application/json" \
  -F "worker.js=@$SCRIPT_DIR/worker.js;type=application/javascript+module")

if [[ $(echo "$RESP" | jq -r .success) != "true" ]]; then
  echo "$RESP" | jq . >&2; exit 1
fi
echo "deployed: $(echo "$RESP" | jq -r '.result.deployment_id')"

put_secret() {
  local name="$1" value="$2"
  [[ -z "$value" ]] && { echo "  skip $name (not set)"; return; }
  local resp
  resp=$(curl -sS -X PUT \
    -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
    -H 'Content-Type: application/json' \
    "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$WORKER_SCRIPT/secrets" \
    --data "$(jq -n --arg n "$name" --arg v "$value" '{name:$n,text:$v,type:"secret_text"}')")
  if [[ $(echo "$resp" | jq -r .success) != "true" ]]; then
    echo "$resp" | jq . >&2; exit 1
  fi
  echo "  set $name"
}

echo "Syncing Worker secrets ..."
put_secret FILBEAM_ACCOUNT_ID "${FILBEAM_ACCOUNT_ID:-}"
put_secret FILBEAM_D1_TOKEN   "${FILBEAM_D1_TOKEN:-}"
put_secret D1_MAINNET         "${D1_MAINNET:-}"
put_secret D1_CALIBRATION     "${D1_CALIBRATION:-}"
