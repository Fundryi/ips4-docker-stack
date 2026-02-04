#!/bin/bash
# Fix SSL certificate issues by cleaning up stale/corrupt state
# Usage: ./scripts/fix-ssl.sh
#
# This script fixes common SSL issues:
# - "No such authorization" errors
# - Stale account registration without certificates
# - Corrupt certbot state

set -e

echo "==> SSL Fix Script"
echo ""

# Check if we're in the right directory
if [ ! -f "compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
    echo "Error: Please run this script from the project root directory"
    echo "       (the directory containing compose.yaml)"
    exit 1
fi

# Check if ssl directory exists
if [ ! -d "data/ssl" ]; then
    echo "No SSL data directory found. Nothing to fix."
    echo "Run ./scripts/init-ssl.sh to set up SSL."
    exit 0
fi

# Check if certificates actually exist
if [ -d "data/ssl/live" ] && [ -n "$(ls -A data/ssl/live 2>/dev/null)" ]; then
    echo "==> Found existing certificates in data/ssl/live/"
    ls -la data/ssl/live/
    echo ""

    # Check if symlinks exist and are valid
    if [ -L "data/ssl/fullchain.pem" ] && [ -L "data/ssl/privkey.pem" ]; then
        if [ -e "data/ssl/fullchain.pem" ] && [ -e "data/ssl/privkey.pem" ]; then
            echo "==> Symlinks are valid. SSL appears to be working."
            echo "    If you're still having issues, try: docker compose down && docker compose up -d"
            exit 0
        else
            echo "==> Symlinks exist but are broken. Will fix them."
        fi
    fi

    # Fix symlinks for existing certificates
    echo "==> Fixing certificate symlinks..."
    cd data/ssl
    for domain_dir in live/*/; do
        if [ -d "$domain_dir" ]; then
            domain=$(basename "$domain_dir")
            echo "    Found certificate for: $domain"
            ln -sf "live/$domain/fullchain.pem" fullchain.pem
            ln -sf "live/$domain/privkey.pem" privkey.pem
            echo "    Symlinks created."
        fi
    done
    cd ../..

    echo ""
    echo "==> Symlinks fixed! Try starting the stack:"
    echo "    docker compose up -d"
    exit 0
fi

# No certificates exist - check for stale state
echo "==> No certificates found. Checking for stale certbot state..."

STALE_STATE=false
if [ -d "data/ssl/accounts" ]; then
    echo "    Found stale accounts directory"
    STALE_STATE=true
fi
if [ -d "data/ssl/renewal" ] && [ -n "$(ls -A data/ssl/renewal 2>/dev/null)" ]; then
    echo "    Found stale renewal configs"
    STALE_STATE=true
fi

if [ "$STALE_STATE" = true ]; then
    echo ""
    echo "==> Cleaning up stale certbot state..."
    rm -rf data/ssl/accounts
    rm -rf data/ssl/renewal
    rm -rf data/ssl/renewal-hooks
    rm -f data/ssl/cloudflare.ini
    rm -f data/ssl/fullchain.pem
    rm -f data/ssl/privkey.pem
    echo "    Cleanup complete."
    echo ""
    echo "==> Now run the SSL initialization script:"
    echo "    ./scripts/init-ssl.sh"
else
    echo "    No stale state found."
    echo ""
    echo "==> To set up SSL, run:"
    echo "    ./scripts/init-ssl.sh"
fi
