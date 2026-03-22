#!/bin/sh
set -e

# Cloudflare Tunnel entrypoint — self-provisioning
# Priority:
#   1. TUNNEL_TOKEN set         → run named tunnel directly
#   2. CF_API_TOKEN set         → auto-create/find tunnel, configure, then run
#   3. Neither                  → quick tunnel (random *.trycloudflare.com URL)

if [ -n "$TUNNEL_TOKEN" ]; then
  echo "cloudflared: using named tunnel (token provided)"
  exec cloudflared tunnel --no-autoupdate run --token "$TUNNEL_TOKEN"
fi

if [ -z "$CF_API_TOKEN" ]; then
  echo "cloudflared: no TUNNEL_TOKEN or CF_API_TOKEN set, using quick tunnel (random URL)"
  exec cloudflared tunnel --no-autoupdate --url http://nginx:80
fi

# --- Auto-provisioning via Cloudflare API ---
TUNNEL_NAME="${CF_TUNNEL_NAME:-ips4}"

# Subdomain and zone are required for auto-provisioning
if [ -z "$CF_ZONE" ]; then
  echo "cloudflared: ERROR — CF_ZONE is required for auto-provisioning."
  echo "  Set CLOUDFLARE_TUNNEL_ZONE in .env (e.g., example.com)"
  exit 1
fi

ZONE="$CF_ZONE"

# If no subdomain, use zone root
if [ -n "$CF_SUBDOMAIN" ]; then
  FQDN="${CF_SUBDOMAIN}.${ZONE}"
else
  FQDN="${ZONE}"
fi

echo "cloudflared: auto-provisioning tunnel '$TUNNEL_NAME' for $FQDN"

AUTH="Authorization: Bearer $CF_API_TOKEN"
CT="Content-Type: application/json"

# Step 1: Get Zone ID + Account ID (from zone response — avoids /accounts permission issues)
echo "  [1/4] Fetching zone and account info for $ZONE..."
ZONES=$(curl -sf -H "$AUTH" "https://api.cloudflare.com/client/v4/zones?name=$ZONE")
ZONE_ID=$(echo "$ZONES" | jq -r '.result[0].id // empty')
ACCOUNT_ID=$(echo "$ZONES" | jq -r '.result[0].account.id // empty')
if [ -z "$ZONE_ID" ] || [ -z "$ACCOUNT_ID" ]; then
  echo "  ERROR: Zone '$ZONE' not found or no account access."
  echo "  API response: $(echo "$ZONES" | jq -c .)"
  exit 1
fi
echo "  Zone ID: $ZONE_ID"
echo "  Account ID: $ACCOUNT_ID"

# Step 2: Create or find existing tunnel
echo "  [2/4] Finding or creating tunnel '$TUNNEL_NAME'..."
TUNNEL_ID=""
FETCHED_TOKEN=""

# Check for existing tunnel
LIST=$(curl -sf -H "$AUTH" "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel?name=$TUNNEL_NAME&is_deleted=false")
TUNNEL_ID=$(echo "$LIST" | jq -r '.result[0].id // empty')

if [ -n "$TUNNEL_ID" ]; then
  echo "  Tunnel exists: $TUNNEL_ID"
else
  echo "  Creating new tunnel..."
  SECRET=$(head -c 32 /dev/urandom | base64)
  CREATE_BODY=$(jq -n --arg name "$TUNNEL_NAME" --arg secret "$SECRET" \
    '{name: $name, tunnel_secret: $secret, config_src: "cloudflare"}')
  CREATE_RESP=$(curl -sf -H "$AUTH" -H "$CT" -X POST \
    "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel" \
    -d "$CREATE_BODY")
  TUNNEL_ID=$(echo "$CREATE_RESP" | jq -r '.result.id // empty')
  if [ -z "$TUNNEL_ID" ]; then
    echo "  ERROR: Failed to create tunnel"
    echo "$CREATE_RESP" | jq .
    exit 1
  fi
  echo "  Created tunnel: $TUNNEL_ID"
fi

# Fetch token for the tunnel
TOKEN_RESP=$(curl -sf -H "$AUTH" "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/token")
FETCHED_TOKEN=$(echo "$TOKEN_RESP" | jq -r '.result // empty')
if [ -z "$FETCHED_TOKEN" ]; then
  echo "  ERROR: Could not retrieve tunnel token"
  exit 1
fi

# Step 3: Build ingress rules (primary + optional extra hostnames)
echo "  [3/4] Configuring ingress..."

# CF_ORIGIN_HOST rewrites the Host header so IPS4's base_url check doesn't redirect
ORIGIN_OPTS=""
if [ -n "$CF_ORIGIN_HOST" ]; then
  ORIGIN_OPTS=",\"originRequest\":{\"httpHostHeader\":\"$CF_ORIGIN_HOST\"}"
fi

INGRESS_RULES="[{\"hostname\":\"$FQDN\",\"service\":\"http://nginx:80\"$ORIGIN_OPTS}"

# CF_EXTRA_ROUTES: comma-separated "subdomain=service" pairs for additional hostnames
# Example: CF_EXTRA_ROUTES="api=http://nginx:80,status=http://status-service:8080"
if [ -n "$CF_EXTRA_ROUTES" ]; then
  IFS=',' ; for route in $CF_EXTRA_ROUTES; do
    ROUTE_SUB=$(echo "$route" | cut -d= -f1)
    ROUTE_SVC=$(echo "$route" | cut -d= -f2-)
    ROUTE_FQDN="$ROUTE_SUB.$ZONE"
    INGRESS_RULES="$INGRESS_RULES,{\"hostname\":\"$ROUTE_FQDN\",\"service\":\"$ROUTE_SVC\"}"
    echo "  + $ROUTE_FQDN -> $ROUTE_SVC"
  done
  unset IFS
fi

# Catch-all 404
INGRESS_RULES="$INGRESS_RULES,{\"service\":\"http_status:404\"}]"

INGRESS_BODY="{\"config\":{\"ingress\":$INGRESS_RULES}}"
echo "  Primary: $FQDN -> http://nginx:80"
curl -sf -H "$AUTH" -H "$CT" -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/cfd_tunnel/$TUNNEL_ID/configurations" \
  -d "$INGRESS_BODY" > /dev/null 2>&1 || echo "  WARNING: Ingress config may have failed"
echo "  Ingress configured"

# Step 4: Create DNS CNAME records
echo "  [4/4] Ensuring DNS records..."
CNAME_TARGET="$TUNNEL_ID.cfargotunnel.com"

# Helper: ensure a CNAME record exists
ensure_cname() {
  local sub="$1"
  local fqdn="$2"
  local target="$3"

  DNS_LIST=$(curl -sf -H "$AUTH" "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?name=$fqdn&type=CNAME")
  EXISTING_ID=$(echo "$DNS_LIST" | jq -r '.result[0].id // empty')
  EXISTING_CONTENT=$(echo "$DNS_LIST" | jq -r '.result[0].content // empty')

  DNS_BODY=$(jq -n --arg name "$sub" --arg content "$target" \
    '{type: "CNAME", name: $name, content: $content, proxied: true, ttl: 1}')

  if [ -n "$EXISTING_ID" ]; then
    if [ "$EXISTING_CONTENT" = "$target" ]; then
      echo "  $fqdn: CNAME OK"
    else
      curl -sf -H "$AUTH" -H "$CT" -X PATCH \
        "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$EXISTING_ID" \
        -d "$DNS_BODY" > /dev/null
      echo "  $fqdn: CNAME updated"
    fi
  else
    curl -sf -H "$AUTH" -H "$CT" -X POST \
      "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records" \
      -d "$DNS_BODY" > /dev/null 2>&1 || echo "  $fqdn: WARNING — DNS create failed"
    echo "  $fqdn: CNAME created"
  fi
}

# Primary record
if [ -n "$CF_SUBDOMAIN" ]; then
  ensure_cname "$CF_SUBDOMAIN" "$FQDN" "$CNAME_TARGET"
else
  ensure_cname "@" "$FQDN" "$CNAME_TARGET"
fi

# Extra route subdomains
if [ -n "$CF_EXTRA_ROUTES" ]; then
  IFS=',' ; for route in $CF_EXTRA_ROUTES; do
    ROUTE_SUB=$(echo "$route" | cut -d= -f1)
    ensure_cname "$ROUTE_SUB" "$ROUTE_SUB.$ZONE" "$CNAME_TARGET"
  done
  unset IFS
fi

echo ""
echo "cloudflared: tunnel ready at https://$FQDN"
if [ -n "$CF_EXTRA_ROUTES" ]; then
  IFS=',' ; for route in $CF_EXTRA_ROUTES; do
    ROUTE_SUB=$(echo "$route" | cut -d= -f1)
    echo "cloudflared: + https://$ROUTE_SUB.$ZONE"
  done
  unset IFS
fi
echo "cloudflared: starting connector..."

exec cloudflared tunnel --no-autoupdate run --token "$FETCHED_TOKEN"
