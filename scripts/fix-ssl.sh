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

# Data directory (standard location for persistent Docker data)
DATA_DIR="/srv/docker-data/ips4"

echo "==> SSL Fix Script"
echo "==> Data directory: $DATA_DIR"
echo ""

# Check if we're in the right directory
if [ ! -f "compose.yaml" ] && [ ! -f "docker-compose.yml" ]; then
    echo "Error: Please run this script from the project root directory"
    echo "       (the directory containing compose.yaml)"
    exit 1
fi

# Check if ssl directory exists
if [ ! -d "$DATA_DIR/ssl" ]; then
    echo "No SSL data directory found at $DATA_DIR/ssl"
    echo "Run: bash scripts/init-ssl.sh"
    exit 0
fi

# Check if certificates actually exist in live/
if [ -d "$DATA_DIR/ssl/live" ] && [ -n "$(ls -A $DATA_DIR/ssl/live 2>/dev/null)" ]; then
    echo "==> Found existing certificates in $DATA_DIR/ssl/live/"
    ls -la "$DATA_DIR/ssl/live/"
    echo ""

    # Find the domain directory
    for domain_dir in "$DATA_DIR/ssl/live"/*/; do
        if [ -d "$domain_dir" ]; then
            domain=$(basename "$domain_dir")
            echo "==> Found certificate for: $domain"

            # Check if the source files exist (following symlinks)
            if [ -e "$DATA_DIR/ssl/live/$domain/fullchain.pem" ] && [ -e "$DATA_DIR/ssl/live/$domain/privkey.pem" ]; then
                echo "==> Copying certificate files (fixes Docker volume mount issues)..."
                # Use cp -L to follow symlinks and copy actual content
                cp -L "$DATA_DIR/ssl/live/$domain/fullchain.pem" "$DATA_DIR/ssl/fullchain.pem"
                cp -L "$DATA_DIR/ssl/live/$domain/privkey.pem" "$DATA_DIR/ssl/privkey.pem"
                chmod 644 "$DATA_DIR/ssl/fullchain.pem"
                chmod 600 "$DATA_DIR/ssl/privkey.pem"
                echo "    Certificate files copied to $DATA_DIR/ssl/"
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
if [ -d "$DATA_DIR/ssl/accounts" ]; then
    echo "    Found stale accounts directory"
    STALE_STATE=true
fi
if [ -d "$DATA_DIR/ssl/renewal" ] && [ -n "$(ls -A $DATA_DIR/ssl/renewal 2>/dev/null)" ]; then
    echo "    Found stale renewal configs"
    STALE_STATE=true
fi

# Also clean up any directory that should be a file
if [ -d "$DATA_DIR/ssl/cloudflare.ini" ]; then
    echo "    Found cloudflare.ini as directory (should be file)"
    rm -rf "$DATA_DIR/ssl/cloudflare.ini"
    STALE_STATE=true
fi

if [ "$STALE_STATE" = true ]; then
    echo ""
    echo "==> Cleaning up stale certbot state..."
    rm -rf "$DATA_DIR/ssl/accounts"
    rm -rf "$DATA_DIR/ssl/renewal"
    rm -rf "$DATA_DIR/ssl/renewal-hooks"
    rm -f "$DATA_DIR/ssl/cloudflare.ini"
    rm -f "$DATA_DIR/ssl/fullchain.pem"
    rm -f "$DATA_DIR/ssl/privkey.pem"
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
