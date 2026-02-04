#!/bin/bash
# Initialize SSL certificates with Let's Encrypt
# Usage: ./scripts/init-ssl.sh [domain] [email]
# If domain and email are not provided, they will be read from .env file

set -e

# Try to read from .env file if it exists
if [ -f .env ]; then
    # Source DOMAIN and CERTBOT_EMAIL from .env file
    export $(grep -v '^#' .env | grep -E '^(DOMAIN|CERTBOT_EMAIL)=' | xargs 2>/dev/null) || true
fi

# Use provided arguments or fall back to .env values
DOMAIN=${1:-$DOMAIN}
EMAIL=${2:-$CERTBOT_EMAIL}

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Error: Domain and email are required!"
    echo ""
    echo "Usage: $0 [domain] [email]"
    echo "Example: $0 example.com admin@example.com"
    echo ""
    echo "Alternatively, set DOMAIN and CERTBOT_EMAIL in your .env file:"
    echo "  DOMAIN=example.com"
    echo "  CERTBOT_EMAIL=admin@example.com"
    exit 1
fi

echo "==> Using domain: $DOMAIN"
echo "==> Using email: $EMAIL"
echo ""

echo "==> Creating required directories..."
mkdir -p data/ssl data/certbot/www data/certbot/logs

echo "==> Stopping any running containers to free ports..."
docker compose down 2>/dev/null || true

echo "==> Starting nginx for ACME challenge..."
docker compose up -d nginx

echo "==> Waiting for nginx to be ready..."
sleep 5

echo "==> Requesting certificate for $DOMAIN..."
docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    -d "$DOMAIN"

echo "==> Stopping nginx..."
docker compose down

echo "==> Creating certificate symlinks..."
ln -sf "live/$DOMAIN/fullchain.pem" data/ssl/fullchain.pem
ln -sf "live/$DOMAIN/privkey.pem" data/ssl/privkey.pem

echo "==> Enabling HTTPS in .env..."
if [ -f .env ]; then
    if grep -q "^#COMPOSE_PROFILES=https" .env; then
        sed -i 's/^#COMPOSE_PROFILES=https/COMPOSE_PROFILES=https/' .env
        echo "    Uncommented COMPOSE_PROFILES=https"
    elif grep -q "^COMPOSE_PROFILES=https" .env; then
        echo "    COMPOSE_PROFILES=https already enabled"
    else
        echo "COMPOSE_PROFILES=https" >> .env
        echo "    Added COMPOSE_PROFILES=https"
    fi
else
    echo "    Warning: .env file not found. Create it from .env.example and set COMPOSE_PROFILES=https"
fi

echo ""
echo "==> SSL setup complete!"
echo "    Start with: docker compose up -d"
