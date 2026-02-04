#!/bin/bash
# Initialize SSL certificates with Let's Encrypt
# Usage: ./scripts/init-ssl.sh yourdomain.com your@email.com

set -e

DOMAIN=${1:-}
EMAIL=${2:-}

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Usage: $0 <domain> <email>"
    echo "Example: $0 example.com admin@example.com"
    exit 1
fi

echo "==> Creating required directories..."
mkdir -p data/ssl data/certbot/www data/certbot/logs

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

echo ""
echo "==> SSL setup complete!"
echo "    Start with HTTPS: docker compose --profile https up -d"
