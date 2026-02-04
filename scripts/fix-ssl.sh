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

# Try to read SSL_PATH from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | grep -E '^(DOMAIN|SSL_PATH)=' | xargs 2>/dev/null) || true
fi

# SSL path - persistent location outside git-managed directory
SSL_PATH="${SSL_PATH:-/etc/komodo/ssl/ips4}"

echo "==> SSL path: $SSL_PATH"
echo ""

# Check if ssl directory exists
if [ ! -d "$SSL_PATH" ]; then
    echo "No SSL data directory found at $SSL_PATH"
    echo "Run: bash scripts/init-ssl.sh"
    exit 0
fi

# Check if certificates actually exist in live/
if [ -d "$SSL_PATH/live" ] && [ -n "$(ls -A $SSL_PATH/live 2>/dev/null)" ]; then
    echo "==> Found existing certificates in $SSL_PATH/live/"
    ls -la "$SSL_PATH/live/"
    echo ""

    # Find the domain directory
    for domain_dir in "$SSL_PATH/live"/*/; do
        if [ -d "$domain_dir" ]; then
            domain=$(basename "$domain_dir")
            echo "==> Found certificate for: $domain"

            # Check if the source files exist (following symlinks)
            if [ -e "$SSL_PATH/live/$domain/fullchain.pem" ] && [ -e "$SSL_PATH/live/$domain/privkey.pem" ]; then
                echo "==> Copying certificate files (fixes Docker volume mount issues)..."
                # Use cp -L to follow symlinks and copy actual content
                cp -L "$SSL_PATH/live/$domain/fullchain.pem" "$SSL_PATH/fullchain.pem"
                cp -L "$SSL_PATH/live/$domain/privkey.pem" "$SSL_PATH/privkey.pem"
                chmod 644 "$SSL_PATH/fullchain.pem"
                chmod 600 "$SSL_PATH/privkey.pem"
                echo "    Certificate files copied to $SSL_PATH/"
                echo ""
                echo "==> SSL fixed! Restart the stack:"
                echo "    docker compose down && docker compose up -d"
                exit 0
            else
                echo "    Warning: Certificate files in live/$domain/ are broken"
            fi
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

STALE_STATE=false
if [ -d "$SSL_PATH/accounts" ]; then
    echo "    Found stale accounts directory"
    STALE_STATE=true
fi
if [ -d "$SSL_PATH/renewal" ] && [ -n "$(ls -A $SSL_PATH/renewal 2>/dev/null)" ]; then
    echo "    Found stale renewal configs"
    STALE_STATE=true
fi

# Also clean up any directory that should be a file
if [ -d "$SSL_PATH/cloudflare.ini" ]; then
    echo "    Found cloudflare.ini as directory (should be file)"
    rm -rf "$SSL_PATH/cloudflare.ini"
    STALE_STATE=true
fi

if [ "$STALE_STATE" = true ]; then
    echo ""
    echo "==> Cleaning up stale certbot state..."
    rm -rf "$SSL_PATH/accounts"
    rm -rf "$SSL_PATH/renewal"
    rm -rf "$SSL_PATH/renewal-hooks"
    rm -f "$SSL_PATH/cloudflare.ini"
    rm -f "$SSL_PATH/fullchain.pem"
    rm -f "$SSL_PATH/privkey.pem"
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
