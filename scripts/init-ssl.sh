#!/bin/bash
# Initialize SSL certificates with Let's Encrypt
# Usage: ./scripts/init-ssl.sh [--staging] [domain] [email]
# If domain and email are not provided, they will be read from .env file
# Uses DNS challenge (Cloudflare) if CLOUDFLARE_API_TOKEN is set, otherwise HTTP challenge
#
# Options:
#   --staging    Use Let's Encrypt staging environment (for testing, avoids rate limits)
#   --force      Force certificate renewal even if valid certificate exists

set -e

# Parse flags
STAGING=false
FORCE=false
while [[ "$1" == --* ]]; do
    case "$1" in
        --staging)
            STAGING=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Try to read from .env file if it exists
if [ -f .env ]; then
    # Source variables from .env file
    export $(grep -v '^#' .env | grep -E '^(DOMAIN|CERTBOT_EMAIL|CLOUDFLARE_API_TOKEN)=' | xargs 2>/dev/null) || true
fi

# Use provided arguments or fall back to .env values
DOMAIN=${1:-$DOMAIN}
EMAIL=${2:-$CERTBOT_EMAIL}

if [ -z "$DOMAIN" ] || [ -z "$EMAIL" ]; then
    echo "Error: Domain and email are required!"
    echo ""
    echo "Usage: $0 [--staging] [--force] [domain] [email]"
    echo "Example: $0 example.com admin@example.com"
    echo "Example: $0 --staging example.com admin@example.com  (test mode)"
    echo ""
    echo "Options:"
    echo "  --staging  Use Let's Encrypt staging (test certificates, no rate limits)"
    echo "  --force    Force renewal even if certificate is still valid"
    echo ""
    echo "Alternatively, set DOMAIN and CERTBOT_EMAIL in your .env file:"
    echo "  DOMAIN=example.com"
    echo "  CERTBOT_EMAIL=admin@example.com"
    exit 1
fi

echo "==> Using domain: $DOMAIN"
echo "==> Using email: $EMAIL"

# Determine challenge type
if [ -n "$CLOUDFLARE_API_TOKEN" ]; then
    CHALLENGE_TYPE="dns"
    echo "==> Using DNS challenge (Cloudflare)"
else
    CHALLENGE_TYPE="http"
    echo "==> Using HTTP challenge (port 80 must be accessible)"
fi

# Show staging warning
if [ "$STAGING" = true ]; then
    echo "==> STAGING MODE: Using Let's Encrypt test environment"
    echo "    Certificates will NOT be trusted by browsers!"
    echo "    Use this for testing only."
    STAGING_FLAG="--staging"
else
    STAGING_FLAG=""
fi
echo ""

# Check if certificate already exists and is valid for at least 30 days
CERT_PATH="data/ssl/live/$DOMAIN/fullchain.pem"
if [ -f "$CERT_PATH" ] && [ "$FORCE" = false ]; then
    echo "==> Checking existing certificate..."
    # Check if certificate expires in more than 30 days
    if openssl x509 -checkend 2592000 -noout -in "$CERT_PATH" 2>/dev/null; then
        EXPIRY_DATE=$(openssl x509 -enddate -noout -in "$CERT_PATH" 2>/dev/null | cut -d= -f2)
        echo "    Certificate is still valid (expires: $EXPIRY_DATE)"
        echo "    Skipping certificate request to avoid Let's Encrypt rate limits."
        echo "    Use --force to request a new certificate anyway."
        echo ""

        # Copy certificate files (symlinks don't work well with Docker volume mounts)
        echo "==> Copying certificate files..."
        cp -L "data/ssl/live/$DOMAIN/fullchain.pem" data/ssl/fullchain.pem
        cp -L "data/ssl/live/$DOMAIN/privkey.pem" data/ssl/privkey.pem
        chmod 644 data/ssl/fullchain.pem
        chmod 600 data/ssl/privkey.pem
        echo "    Certificate files copied"

        echo "==> Enabling HTTPS in .env..."
        if [ -f .env ]; then
            if grep -q "^COMPOSE_PROFILES=" .env; then
                sed -i 's/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=https/' .env
                echo "    Set COMPOSE_PROFILES=https"
            else
                echo "COMPOSE_PROFILES=https" >> .env
                echo "    Added COMPOSE_PROFILES=https"
            fi
        fi

        echo ""
        echo "==> SSL setup complete! (using existing certificate)"
        echo "    Start with: docker compose up -d"
        exit 0
    else
        echo "    Certificate expires within 30 days, will renew..."
    fi
fi

echo "==> Creating required directories..."
mkdir -p data/ssl data/certbot/www data/certbot/logs certbot

# Remove cloudflare.ini if it's a directory (can happen from failed syncs)
if [ -d "certbot/cloudflare.ini" ]; then
    rm -rf "certbot/cloudflare.ini"
fi
if [ -d "data/ssl/cloudflare.ini" ]; then
    rm -rf "data/ssl/cloudflare.ini"
fi

# Check for stale certbot state (accounts exist but no certificates)
# This can cause "No such authorization" errors
if [ -d "data/ssl/accounts" ] && [ ! -d "data/ssl/live" ]; then
    echo "==> Detected stale certbot state, cleaning up..."
    rm -rf data/ssl/accounts
    rm -rf data/ssl/renewal
    rm -rf data/ssl/renewal-hooks
    rm -f data/ssl/cloudflare.ini
    echo "    Cleanup complete."
fi

echo "==> Stopping any running containers to free ports..."
docker compose down 2>/dev/null || true

if [ "$CHALLENGE_TYPE" = "dns" ]; then
    # DNS Challenge (Cloudflare)
    echo "==> Creating Cloudflare credentials file..."
    cat > certbot/cloudflare.ini << EOF
# Cloudflare API credentials - auto-generated by init-ssl.sh
dns_cloudflare_api_token = $CLOUDFLARE_API_TOKEN
EOF
    chmod 600 certbot/cloudflare.ini

    echo "==> Requesting certificate via DNS challenge..."
    docker run --rm \
        -v "$(pwd)/data/ssl:/etc/letsencrypt" \
        -v "$(pwd)/data/certbot/logs:/var/log/letsencrypt" \
        -v "$(pwd)/certbot/cloudflare.ini:/etc/letsencrypt/cloudflare.ini:ro" \
        certbot/dns-cloudflare:latest certonly \
        $STAGING_FLAG \
        --dns-cloudflare \
        --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini \
        --dns-cloudflare-propagation-seconds 30 \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN"
else
    # HTTP Challenge
    echo "==> Starting nginx for ACME challenge..."
    docker compose --profile http up -d nginx

    echo "==> Waiting for nginx to be ready..."
    sleep 5

    echo "==> Requesting certificate via HTTP challenge..."
    docker compose --profile http run --rm certbot certonly \
        $STAGING_FLAG \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN"

    echo "==> Stopping nginx..."
    docker compose --profile http down
fi

echo "==> Copying certificate files..."
# Copy actual files instead of symlinks (symlinks don't work well with Docker volume mounts)
cp -L "data/ssl/live/$DOMAIN/fullchain.pem" data/ssl/fullchain.pem
cp -L "data/ssl/live/$DOMAIN/privkey.pem" data/ssl/privkey.pem
chmod 644 data/ssl/fullchain.pem
chmod 600 data/ssl/privkey.pem
echo "    Certificate files copied to data/ssl/"

echo "==> Enabling HTTPS in .env..."
if [ -f .env ]; then
    if grep -q "^COMPOSE_PROFILES=" .env; then
        sed -i 's/^COMPOSE_PROFILES=.*/COMPOSE_PROFILES=https/' .env
        echo "    Set COMPOSE_PROFILES=https"
    else
        echo "COMPOSE_PROFILES=https" >> .env
        echo "    Added COMPOSE_PROFILES=https"
    fi
else
    echo "    Warning: .env file not found. Create it from .env.example and set COMPOSE_PROFILES=https"
fi

echo ""
if [ "$STAGING" = true ]; then
    echo "==> SSL setup complete! (STAGING certificate - NOT trusted by browsers)"
    echo "    To get a real certificate, run: bash scripts/init-ssl.sh --force"
else
    echo "==> SSL setup complete!"
fi
echo "    Start with: docker compose up -d"
