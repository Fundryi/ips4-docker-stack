#!/bin/bash
# Fix SSL certificate issues by cleaning up stale/corrupt state
# Usage: ./scripts/fix-ssl.sh
#
# This script fixes common SSL issues:
# - "No such authorization" errors
# - Stale account registration without certificates
# - Corrupt certbot state
# - Broken symlinks (converts to copies for Docker compatibility)

set -e

echo "==> SSL Fix Script"
echo ""

# Check if we're in the right directory
if [ ! -f "compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
    echo "Error: Please run this script from the project root directory"
    echo "       (the directory containing compose.yaml)"
    exit 1
fi

# Get the project name for the Docker volume (used by compose)
PROJECT_NAME=$(basename "$(pwd)" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')
VOLUME_NAME="${PROJECT_NAME}_ssl-certs"

echo "==> Using Docker volume: $VOLUME_NAME"
echo ""

# Check if the volume exists
if ! docker volume inspect "$VOLUME_NAME" >/dev/null 2>&1; then
    echo "No SSL volume found ($VOLUME_NAME). Nothing to fix."
    echo "Run: bash scripts/init-ssl.sh"
    exit 0
fi

# Check if certificates actually exist in the volume
echo "==> Checking for certificates in volume..."
LIVE_DIRS=$(docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt:ro" alpine sh -c \
    "ls -d /etc/letsencrypt/live/*/ 2>/dev/null || true")

if [ -n "$LIVE_DIRS" ]; then
    echo "==> Found certificate directories in volume"
    docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt:ro" alpine ls -la /etc/letsencrypt/live/
    echo ""

    # Find the domain directory and copy certificates
    for domain in $(docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt:ro" alpine sh -c \
        "ls /etc/letsencrypt/live/ 2>/dev/null | grep -v README"); do
        echo "==> Found certificate for: $domain"

        # Check if the source files exist (following symlinks)
        CERT_EXISTS=$(docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt:ro" alpine sh -c \
            "[ -e /etc/letsencrypt/live/$domain/fullchain.pem ] && [ -e /etc/letsencrypt/live/$domain/privkey.pem ] && echo 'yes' || echo 'no'")

        if [ "$CERT_EXISTS" = "yes" ]; then
            echo "==> Copying certificate files within volume..."
            docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt" alpine sh -c \
                "cp -L /etc/letsencrypt/live/$domain/fullchain.pem /etc/letsencrypt/fullchain.pem && \
                 cp -L /etc/letsencrypt/live/$domain/privkey.pem /etc/letsencrypt/privkey.pem && \
                 chmod 644 /etc/letsencrypt/fullchain.pem && \
                 chmod 600 /etc/letsencrypt/privkey.pem"
            echo "    Certificate files copied"
            echo ""
            echo "==> SSL fixed! Restart the stack:"
            echo "    docker compose down && docker compose up -d"
            exit 0
        else
            echo "    Warning: Certificate files in live/$domain/ are broken"
        fi
    done

    echo ""
    echo "==> Certificate directories exist but files are missing/broken."
    echo "    You may need to request a new certificate:"
    echo "    bash scripts/init-ssl.sh --force"
    exit 1
fi

# No certificates exist - check for stale state
echo "==> No certificates found. Checking for stale certbot state..."

STALE_STATE=$(docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt:ro" alpine sh -c \
    "[ -d /etc/letsencrypt/accounts ] && echo 'accounts' || true; \
     [ -d /etc/letsencrypt/renewal ] && ls /etc/letsencrypt/renewal/ 2>/dev/null | head -1 && echo 'renewal' || true")

if [ -n "$STALE_STATE" ]; then
    echo "    Found stale certbot state"
    echo ""
    echo "==> Cleaning up stale certbot state in volume..."
    docker run --rm -v "$VOLUME_NAME:/etc/letsencrypt" alpine sh -c \
        "rm -rf /etc/letsencrypt/accounts \
                /etc/letsencrypt/renewal \
                /etc/letsencrypt/renewal-hooks \
                /etc/letsencrypt/cloudflare.ini \
                /etc/letsencrypt/fullchain.pem \
                /etc/letsencrypt/privkey.pem 2>/dev/null || true"
    echo "    Cleanup complete."
    echo ""
    echo "==> Now run the SSL initialization script:"
    echo "    bash scripts/init-ssl.sh"
else
    echo "    No stale state found."
    echo ""
    echo "==> To set up SSL, run:"
    echo "    bash scripts/init-ssl.sh"
fi
