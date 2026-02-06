# IPS4 Docker Stack

Production-ready Docker Compose setup for Invision Community (IPS4) with MySQL 8.4, Redis 7, PHP-FPM 8.1, Nginx, and automatic SSL via Let's Encrypt.

## Features

- **Full IPS4 Support** - PHP 8.1 with all required extensions
- **High Performance** - Redis caching, OPcache, optimized MySQL
- **Automatic SSL** - Let's Encrypt with auto-renewal via Certbot
- **Easy Deployment** - Single command startup, SSL toggle via `.env`

## Quick Start

```bash
# 1. Setup environment
cp .env.example .env
nano .env  # Set your passwords

# 2. Start
docker compose up -d

# 3. Access
open http://localhost
```

## Services

| Service | Description | Port |
|---------|-------------|------|
| `nginx` | Web server (HTTP) | 80 |
| `nginx-https` | Web server (HTTPS) | 80, 443 |
| `php` | PHP-FPM 8.1 | 9000 |
| `db` | MySQL 8.4 | 3306 |
| `redis` | Redis 7 | 6379 |
| `certbot` | SSL renewal | - |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_PASSWORD` | - | MySQL user password (required) |
| `MYSQL_ROOT_PASSWORD` | - | MySQL root password (required) |
| `HTTP_PORT` | `80` | HTTP port |
| `HTTPS_PORT` | `443` | HTTPS port |
| `COMPOSE_PROFILES` | `http` | `http` for HTTP only, `https` for SSL |
| `DOMAIN` | `example.com` | Domain for SSL certificate |
| `CERTBOT_EMAIL` | - | Email for Let's Encrypt notifications |
| `CLOUDFLARE_API_TOKEN` | - | Cloudflare API token for DNS challenge (optional) |

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
   # Komodo users: stacks are typically in /etc/komodo/stacks/ips4/
   cd /etc/komodo/stacks/ips4/

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
   # Leave CLOUDFLARE_API_TOKEN empty or remove it
   ```

2. **Run the SSL script:**
   ```bash
   cd /etc/komodo/stacks/ips4/

   chmod +x scripts/init-ssl.sh
   ./scripts/init-ssl.sh
   docker compose up -d
   ```

### Important Notes

**Run commands on the host machine** (or Komodo periphery container), not inside the IPS4 containers. The script needs access to the project directory and runs `docker compose` commands.

**Find your project path:**
```bash
docker inspect ips4-nginx-1 --format '{{ index .Config.Labels "com.docker.compose.project.working_dir" }}'
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

## Local Development (Windows)

The base `compose.yaml` uses absolute Linux paths (`/srv/docker-data/ips4/...`) for production servers. For local development on Windows, a `compose.override.yaml` remaps these to the local `./data/` directory instead.

### How it works

| | Production (Linux) | Local (Windows) |
|---|---|---|
| Data location | `/srv/docker-data/ips4/` | `./data/` in project dir |
| Override file | Not present | `compose.override.yaml` |
| Files editable via | Server filesystem | Windows Explorer / VS Code |
| SSL setup | `./scripts/init-ssl.sh` | Certbot via Docker (see below) |

Docker Compose automatically loads `compose.override.yaml` when present — no extra flags needed. The override is gitignored so it never affects production.

### Setup

**1. Create `compose.override.yaml`** in the project root:

```yaml
# Local development overrides - NOT committed to git
# Remaps /srv/docker-data/ips4/ paths to local ./data/ for Windows
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

  php:
    volumes:
      - ./data/ips:/var/www/html

  nginx:
    volumes:
      - ./data/ips:/var/www/html:ro
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

### Local HTTPS (optional)

Since the shell scripts can't run on Windows natively, use certbot via Docker with the Cloudflare DNS challenge:

```powershell
# 1. Create cloudflare credentials
echo dns_cloudflare_api_token = YOUR_TOKEN > data/ssl/cloudflare.ini

# 2. Get certificate (no port 80 needed)
docker run --rm -v "%cd%/data/ssl:/etc/letsencrypt" certbot/dns-cloudflare certonly --dns-cloudflare --dns-cloudflare-credentials /etc/letsencrypt/cloudflare.ini -d yourdomain.com --email you@email.com --agree-tos --no-eff-email

# 3. Copy certs to where nginx expects them
copy data\ssl\live\yourdomain.com\fullchain.pem data\ssl\fullchain.pem
copy data\ssl\live\yourdomain.com\privkey.pem data\ssl\privkey.pem
```

Then set `COMPOSE_PROFILES=https` in `.env` and add your domain to `C:\Windows\System32\drivers\etc\hosts`:

```
127.0.0.1  yourdomain.com
```

## IPS4 Installation

1. Extract IPS4 files to `data/ips/`
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
docker compose exec db mysqldump -u root -p ips > backup.sql  # Backup DB
```

## Directory Structure

```
ips4-docker-stack/
├── compose.yaml              # Main Docker Compose config (production paths)
├── compose.override.yaml     # Local overrides - gitignored (see Local Development)
├── .env                      # Environment config (gitignored)
├── data/
│   ├── ips/                  # IPS4 files (used locally via override)
│   ├── mysql/                # MySQL data
│   ├── redis/                # Redis data
│   ├── ssl/                  # SSL certificates
│   └── certbot/              # Certbot data
├── nginx/                    # Nginx configs (http.conf, https.conf.template)
├── php/                      # PHP-FPM Dockerfile & config
├── mysql/                    # MySQL Dockerfile & config
├── redis/                    # Redis config
└── scripts/                  # SSL init & helper scripts (Linux)
```

> **Note:** On production Linux servers, persistent data lives at `/srv/docker-data/ips4/` (defined in `compose.yaml`). Locally on Windows, `compose.override.yaml` remaps these to `./data/` so files are accessible from your editor.

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Default nginx page | Ensure IPS4 files are in `data/ips/` |
| Database connection failed | Check `docker compose ps db` and verify `.env` passwords |
| SSL errors | Run `bash scripts/fix-ssl.sh` to diagnose and fix |
| SSL "No such authorization" | Run `bash scripts/fix-ssl.sh` then `bash scripts/init-ssl.sh` |
| Port in use | Change `HTTP_PORT` or `HTTPS_PORT` in `.env` |
| Permission denied (IPS files) | Run `sudo chown -R 33:33 data/ips/` (Linux) |
| Permission denied (scripts) | Run `chmod +x scripts/*.sh` or use `bash scripts/...` |

## License

This project is provided as-is for use with Invision Community.
