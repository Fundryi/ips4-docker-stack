# IPS4 Docker Stack

Production-ready Docker Compose setup for Invision Community (IPS4) with MySQL 8.4, Redis 7, PHP-FPM 8.1, Nginx, and automatic SSL via Let's Encrypt.

## Features

- **Full IPS4 Support** - PHP 8.1 with all required extensions + ionCube Loader
- **High Performance** - Redis caching, OPcache, optimized MySQL
- **Automatic SSL** - Let's Encrypt with auto-renewal (DNS or HTTP challenge)
- **Cloudflare Tunnel** - External access without opening ports, with auto-provisioning
- **Automated Backups** - Configurable MySQL backup service with retention
- **Task Scheduler** - Built-in IPS4 cron service
- **Fresh Deploy Ready** - Auto-seeds setup files on first boot
- **Configurable Data Path** - `DATA_DIR` env var for flexible storage location

## Quick Start

```bash
# 1. Setup environment
cp .env.example .env
nano .env  # Set your passwords and DATA_DIR

# 2. Start (pulls pre-built images from ghcr.io)
docker compose up -d

# 3. Access
open http://localhost
```

To build from source instead of pulling pre-built images:

```bash
docker compose up -d --build
```

## Services

| Service | Description | Profile | Port |
|---------|-------------|---------|------|
| `db-init` | MySQL data directory ownership fix | _(always)_ | - |
| `db` | MySQL 8.4 | _(always)_ | 3306 |
| `redis-init` | Redis data directory ownership fix | _(always)_ | - |
| `redis` | Redis 7 | _(always)_ | 6379 |
| `web-init` | Seeds IPS4 placeholder files on fresh deploy | _(always)_ | - |
| `php` | PHP-FPM 8.1 with IPS4 extensions | _(always)_ | 9000 |
| `nginx` | Web server (HTTP only) | `http` | 80 |
| `nginx-https` | Web server (HTTPS) | `https` | 80, 443 |
| `certbot` | SSL certificate renewal | `https` | - |
| `nginx-reload` | Daily nginx reload for cert pickup | `https` | - |
| `db-backup` | Automated MySQL backups | `backup` | - |
| `cron` | IPS4 task scheduler (runs every 60s) | `cron` | - |
| `cloudflared` | Cloudflare Tunnel for external access | `tunnel` | - |
| `cf-devmode` | Keeps Cloudflare dev mode enabled | `tunnel-devmode` | - |

## Nginx Config Files

- `nginx/http.conf` is a static config for the HTTP profile.
- `nginx/https.conf.template` is intentionally a template because it uses `${DOMAIN}` values at runtime.
- In `compose.yaml`, the HTTPS service mounts it to `/etc/nginx/templates/default.conf.template`; the official nginx entrypoint renders it into `/etc/nginx/conf.d/default.conf` on container start.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_DIR` | `/srv/docker-data/ips4` | Base path for all persistent volumes |
| `MYSQL_PASSWORD` | - | MySQL user password (required) |
| `MYSQL_ROOT_PASSWORD` | - | MySQL root password (required) |
| `HTTP_PORT` | `80` | HTTP port |
| `HTTPS_PORT` | `443` | HTTPS port |
| `COMPOSE_PROFILES` | `http` | Comma-separated profiles (see below) |
| `DOMAIN` | `example.com` | Domain for SSL certificate |
| `CERTBOT_EMAIL` | - | Email for Let's Encrypt notifications |
| `CLOUDFLARE_API_TOKEN` | - | Cloudflare API token for DNS challenge |
| `IPS_TASK_KEY` | - | IPS4 task key from ACP (for cron profile) |
| `BACKUP_INTERVAL_HOURS` | `1` | Hours between database backups |
| `BACKUP_RETENTION_DAYS` | `7` | Delete backups older than N days |
| `PHP_VERSION` | `8.1` | PHP major version baked into the image at build time (e.g. `8.2`) |

### PHP / PHP-FPM Tuning (optional)

Baked defaults in `php/php.ini` and `php/www.conf` are production-ready for IPS4. Override at runtime by setting any of the vars below on the `php` service (via `.env` — compose only forwards what's listed, see `compose.override.yaml` for wiring). Unset vars = baked defaults apply.

| Variable | Maps to | Baked default |
|----------|---------|---------------|
| `PHP_MEMORY_LIMIT` | `memory_limit` | `1024M` |
| `PHP_UPLOAD_MAX_FILESIZE` | `upload_max_filesize` | `512M` |
| `PHP_POST_MAX_SIZE` | `post_max_size` | `512M` |
| `PHP_MAX_EXECUTION_TIME` | `max_execution_time` | `300` |
| `PHP_MAX_INPUT_TIME` | `max_input_time` | `300` |
| `PHP_MAX_INPUT_VARS` | `max_input_vars` | `20000` |
| `PHP_DATE_TIMEZONE` | `date.timezone` | `UTC` |
| `PHP_DISPLAY_ERRORS` | `display_errors` | `Off` |
| `PHP_OPCACHE_MEMORY_CONSUMPTION` | `opcache.memory_consumption` | `512` |
| `PHP_OPCACHE_MAX_ACCELERATED_FILES` | `opcache.max_accelerated_files` | `100000` |
| `PHP_OPCACHE_VALIDATE_TIMESTAMPS` | `opcache.validate_timestamps` | `1` |
| `PHP_OPCACHE_REVALIDATE_FREQ` | `opcache.revalidate_freq` | `10` |
| `PHP_OPCACHE_INTERNED_STRINGS_BUFFER` | `opcache.interned_strings_buffer` | `32` |
| `FPM_PM` | `pm` | `dynamic` |
| `FPM_PM_MAX_CHILDREN` | `pm.max_children` | `120` |
| `FPM_PM_START_SERVERS` | `pm.start_servers` | `16` |
| `FPM_PM_MIN_SPARE_SERVERS` | `pm.min_spare_servers` | `16` |
| `FPM_PM_MAX_SPARE_SERVERS` | `pm.max_spare_servers` | `32` |
| `FPM_PM_MAX_REQUESTS` | `pm.max_requests` | `800` |
| `FPM_REQUEST_TERMINATE_TIMEOUT` | `request_terminate_timeout` | `300` |

Overrides are written at container start to `zz-env.ini` / `zz-env.conf` which load after the baked config. Never add DB credentials or other secrets to the `php` service environment.

### Switching PHP Version

The default PHP version is **8.1**. To build against 8.2, set `PHP_VERSION=8.2` in `.env` and rebuild locally (`docker compose build php cron`). Pre-built GHCR images always ship the default version — non-default versions require a local build.

### Profiles

Enable profiles via `COMPOSE_PROFILES` in `.env` (comma-separated):

```bash
# HTTP with cron and backups (recommended)
COMPOSE_PROFILES=http,cron,backup

# HTTPS with all features
COMPOSE_PROFILES=https,cron,backup

# Cloudflare Tunnel (use alongside http profile)
COMPOSE_PROFILES=http,tunnel,cron,backup
```

### Cloudflare Tunnel Variables

| Variable | Description |
|----------|-------------|
| `CLOUDFLARE_TUNNEL_API_TOKEN` | CF API token (Account:Tunnel:Edit + Zone:DNS:Edit) |
| `CLOUDFLARE_TUNNEL_TOKEN` | Pre-provisioned tunnel token (skips auto-provisioning) |
| `CLOUDFLARE_TUNNEL_NAME` | Tunnel name (default: `ips4`) |
| `CLOUDFLARE_TUNNEL_SUBDOMAIN` | Primary subdomain for DNS |
| `CLOUDFLARE_TUNNEL_ZONE` | Cloudflare zone (domain) |
| `CLOUDFLARE_TUNNEL_ORIGIN_HOST` | Origin Host header (must match IPS4 base_url) |
| `CLOUDFLARE_TUNNEL_EXTRA_ROUTES` | Extra sub=service pairs, comma-separated |
| `CF_DEVMODE_ZONE_ID` | Zone ID for dev mode watcher |
| `CF_DEVMODE_API_TOKEN` | API token for dev mode (falls back to tunnel token) |

## SSL/HTTPS Setup

The stack supports two methods for obtaining SSL certificates:
- **DNS Challenge (Cloudflare)** - Works with local/internal domains, no port 80 needed
- **HTTP Challenge** - Traditional method, requires port 80 accessible from internet

### DNS Challenge Setup (Recommended)

Best for local domains, internal networks, or when port 80 isn't available.

1. **Get a Cloudflare API Token:**
   - Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens)
   - Create a token with **Zone:DNS:Edit** permission for your domain

2. **Configure `.env`:**
   ```bash
   DOMAIN=yourdomain.com
   CERTBOT_EMAIL=your@email.com
   CLOUDFLARE_API_TOKEN=your_cloudflare_api_token
   ```

3. **Run the SSL script:**
   ```bash
   chmod +x scripts/init-ssl.sh
   ./scripts/init-ssl.sh
   docker compose up -d
   ```

### HTTP Challenge Setup

Traditional method - requires port 80 to be publicly accessible.

1. **Configure `.env`:**
   ```bash
   DOMAIN=yourdomain.com
   CERTBOT_EMAIL=your@email.com
   # Leave CLOUDFLARE_API_TOKEN empty
   ```

2. **Run the SSL script:**
   ```bash
   chmod +x scripts/init-ssl.sh
   ./scripts/init-ssl.sh
   docker compose up -d
   ```

### Auto-Renewal

Certificates are automatically renewed daily. No cron jobs needed.

### Toggle HTTP/HTTPS

Edit `.env`:
```bash
# HTTP only
COMPOSE_PROFILES=http

# HTTPS enabled
COMPOSE_PROFILES=https
```

Then restart: `docker compose down && docker compose up -d`

## Cloudflare Tunnel

Access your IPS4 instance externally without opening ports. The tunnel auto-provisions on first boot.

**Priority:** `CLOUDFLARE_TUNNEL_TOKEN` (direct) > `CLOUDFLARE_TUNNEL_API_TOKEN` (auto-provision) > quick tunnel (random URL).

1. **Configure `.env`:**
   ```bash
   COMPOSE_PROFILES=http,tunnel,cron,backup
   CLOUDFLARE_TUNNEL_API_TOKEN=your_token
   CLOUDFLARE_TUNNEL_ZONE=yourdomain.com
   CLOUDFLARE_TUNNEL_SUBDOMAIN=forum
   ```

2. **Start:**
   ```bash
   docker compose up -d
   ```

The tunnel service will create a named tunnel, configure ingress, and set up DNS automatically.

> **Note:** The tunnel profile requires the `http` profile to also be active, as it depends on the nginx service.

## Local Development (Windows)

The base `compose.yaml` uses `DATA_DIR` (default `/srv/docker-data/ips4/`) for production servers. For local development on Windows, a `compose.override.yaml` remaps these to the local `./data/` directory instead.

### How it works

| | Production (Linux) | Local (Windows) |
|---|---|---|
| Data location | `DATA_DIR` (default `/srv/docker-data/ips4/`) | `./data/` in project dir |
| Override file | Not present | `compose.override.yaml` |
| Files editable via | Server filesystem | Windows Explorer / VS Code |
| SSL setup | `./scripts/init-ssl.sh` | Certbot via Docker (see below) |

Docker Compose automatically loads `compose.override.yaml` when present — no extra flags needed. The override is gitignored so it never affects production.

### Setup

**1. Create `compose.override.yaml`** in the project root:

```yaml
# Local development overrides - NOT committed to git
# Remaps DATA_DIR paths to local ./data/ for Windows
services:
  db-init:
    volumes:
      - ./data/mysql:/data

  db:
    volumes:
      - ./data/mysql:/var/lib/mysql

  redis-init:
    volumes:
      - ./data/redis:/data

  redis:
    volumes:
      - ./data/redis:/data

  web-init:
    volumes:
      - ./data/ips:/data
      - ./data/ips:/seed:ro

  php:
    volumes:
      - ./data/ips:/var/www/html

  nginx:
    volumes:
      - ./data/ips:/var/www/html:ro
      - ./data/certbot/www:/var/www/certbot:ro
      - ./data/logs/nginx:/var/log/nginx

  nginx-https:
    volumes:
      - ./data/ips:/var/www/html:ro
      - ./data/ssl:/etc/nginx/ssl:ro
      - ./data/certbot/www:/var/www/certbot:ro
      - ./data/logs/nginx:/var/log/nginx

  certbot:
    volumes:
      - ./data/ssl:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
      - ./data/certbot/logs:/var/log/letsencrypt
```

**2. Set HTTP mode** in `.env` (simplest for local):

```
COMPOSE_PROFILES=http
```

**3. Start:**

```powershell
docker compose up -d --build
```

Your IPS4 files in `data/ips/` are now served directly. Open `http://localhost`.

## IPS4 Installation

1. Extract IPS4 files to your data directory (`DATA_DIR/ips/` or `data/ips/` locally)
2. Visit `http://yourdomain.com`
3. Use these database settings:
   - **Host:** `db`
   - **Database:** `ips`
   - **User:** `ips`
   - **Password:** Your `MYSQL_PASSWORD`

4. Enable Redis caching in AdminCP:
   - **Host:** `redis`
   - **Port:** `6379`

## Commands

```bash
docker compose up -d                # Start
docker compose down                 # Stop
docker compose logs -f [service]    # View logs
docker compose restart [service]    # Restart service
docker compose exec db mysqldump -u root -p ips > backup.sql  # Manual DB backup
```

## Directory Structure

```
ips4-docker-stack/
├── .github/workflows/        # CI: co-author check, Docker image publishing
├── compose.yaml              # Main Docker Compose config
├── compose.override.yaml     # Local overrides - gitignored (see Local Development)
├── .env                      # Environment config (gitignored)
├── data/
│   ├── ips/                  # IPS4 placeholder files (setup.php, index.html, ips4.php)
│   ├── mysql/                # MySQL data (gitignored)
│   ├── redis/                # Redis data (gitignored)
│   ├── ssl/                  # SSL certificates (gitignored)
│   └── certbot/              # Certbot data (gitignored)
├── docker/
│   ├── db-backup/            # Automated backup service (Dockerfile + entrypoint)
│   └── cloudflared/          # Cloudflare Tunnel service (Dockerfile + entrypoint)
├── nginx/                    # Nginx configs (http.conf, https.conf.template)
├── php/                      # PHP-FPM Dockerfile & config
├── mysql/                    # MySQL Dockerfile & config
├── redis/                    # Redis config
└── scripts/                  # SSL init & helper scripts (Linux)
```

> **Note:** On production Linux servers, persistent data lives at `DATA_DIR` (default `/srv/docker-data/ips4/`). Locally on Windows, `compose.override.yaml` remaps these to `./data/`.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Default nginx page | Ensure IPS4 files are in your data directory's `ips/` folder |
| 403 on fresh deploy | The `web-init` service seeds placeholder files automatically — check `docker compose logs web-init` |
| Database connection failed | Check `docker compose ps db` and verify `.env` passwords |
| SSL errors | Run `bash scripts/fix-ssl.sh` to diagnose and fix |
| SSL "No such authorization" | Run `bash scripts/fix-ssl.sh` then `bash scripts/init-ssl.sh` |
| Port in use | Change `HTTP_PORT` or `HTTPS_PORT` in `.env` |
| Permission denied (IPS files) | Run `sudo chown -R 33:33 $DATA_DIR/ips/` (Linux) |
| Permission denied (scripts) | Run `chmod +x scripts/*.sh` or use `bash scripts/...` |
| Tunnel can't reach nginx | Ensure `http` profile is active alongside `tunnel` |
| Cron not running | Set `IPS_TASK_KEY` in `.env` (from ACP > System > Advanced Configuration > Tasks) |

## License

This project is provided as-is for use with Invision Community.
