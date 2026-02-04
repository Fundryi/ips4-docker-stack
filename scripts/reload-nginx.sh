#!/bin/bash
# Reload nginx to pick up renewed SSL certificates
# Add to crontab: 0 0 * * * /path/to/scripts/reload-nginx.sh

cd "$(dirname "$0")/.."
docker compose exec -T nginx-https nginx -s reload 2>/dev/null || true
