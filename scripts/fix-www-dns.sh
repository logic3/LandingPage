#!/usr/bin/env bash
# Fix www.lauer.team DNS for GitHub Pages (Cloudflare API).
# Requires: CLOUDFLARE_API_TOKEN with Zone.DNS Edit permission.
set -euo pipefail

ZONE_NAME="lauer.team"
CNAME_TARGET="logic3.github.io"

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "Set CLOUDFLARE_API_TOKEN (Zone.DNS Edit for lauer.team)." >&2
  exit 1
fi

auth=(-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" -H "Content-Type: application/json")

zone_id=$(curl -sf "${auth[@]}" \
  "https://api.cloudflare.com/client/v4/zones?name=${ZONE_NAME}" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['result'][0]['id'])")

echo "Zone ID: ${zone_id}"

# Delete all A/AAAA records on www (GitHub expects CNAME, not A records)
records=$(curl -sf "${auth[@]}" \
  "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records?name=www.${ZONE_NAME}")

echo "${records}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('result', []):
    if r['type'] in ('A', 'AAAA') and r['name'] == 'www.${ZONE_NAME}':
        print(r['id'])
" | while read -r id; do
  [[ -n "${id}" ]] || continue
  echo "Deleting ${id}..."
  curl -sf -X DELETE "${auth[@]}" \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${id}" >/dev/null
done

# Create CNAME if missing
existing_cname=$(echo "${records}" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for r in data.get('result', []):
    if r['type'] == 'CNAME' and r['name'] == 'www.${ZONE_NAME}':
        print(r['id'], r['content'], r.get('proxied', False))
        break
" || true)

if [[ -n "${existing_cname}" ]]; then
  read -r cname_id cname_content proxied <<< "${existing_cname}"
  if [[ "${cname_content}" != "${CNAME_TARGET}" || "${proxied}" == "True" ]]; then
    echo "Updating existing CNAME ${cname_id}..."
    curl -sf -X PATCH "${auth[@]}" \
      "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records/${cname_id}" \
      --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"${CNAME_TARGET}\",\"proxied\":false}" >/dev/null
  else
    echo "CNAME already correct."
  fi
else
  echo "Creating CNAME www -> ${CNAME_TARGET} (DNS only)..."
  curl -sf -X POST "${auth[@]}" \
    "https://api.cloudflare.com/client/v4/zones/${zone_id}/dns_records" \
    --data "{\"type\":\"CNAME\",\"name\":\"www\",\"content\":\"${CNAME_TARGET}\",\"proxied\":false,\"ttl\":1}" >/dev/null
fi

echo "Done. Verify:"
echo "  dig www.${ZONE_NAME} CNAME +short   # should show ${CNAME_TARGET}"
echo "Then re-check GitHub Pages DNS status (may take a few minutes)."
