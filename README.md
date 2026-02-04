# IPS4 Docker Stack

Production-ready Docker Compose setup for Invision Community (IPS4) with MySQL 8.4, Redis 7, PHP-FPM 8.1, Nginx, and automatic SSL via Let's Encrypt.

## Features

- **Full IPS4 Support** - PHP 8.1 with all required extensions
- **High Performance** - Redis caching, OPcache, optimized MySQL
- **Automatic SSL** - Let's Encrypt with auto-renewal via Certbot
- **Easy Deployment** - Single command startup with Docker Compose profiles

## Quick Start

```bash
# 1. Setup environment
cp .env.example .env
nano .env  # Set your passwords

# 2. Start (HTTP)
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
| `DOMAIN` | `example.com` | Domain for SSL certificate |
| `CERTBOT_EMAIL` | - | Email for Let's Encrypt notifications |

## SSL/HTTPS Setup

### Automated Setup (Recommended)

```bash
chmod +x scripts/init-ssl.sh
./scripts/init-ssl.sh yourdomain.com your@email.com
docker compose --profile https up -d
```

### Manual Setup

```bash
# 1. Create directories
mkdir -p data/ssl data/certbot/www data/certbot/logs

# 2. Get certificate
docker compose up -d nginx
docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your@email.com --agree-tos --no-eff-email \
  -d yourdomain.com
docker compose down

# 3. Link certificates
ln -sf live/yourdomain.com/fullchain.pem data/ssl/fullchain.pem
ln -sf live/yourdomain.com/privkey.pem data/ssl/privkey.pem

# 4. Start with HTTPS
docker compose --profile https up -d
```

### Auto-Renewal

With the `https` profile, certificates are automatically renewed daily. No cron jobs needed.

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
docker compose up -d                    # Start (HTTP)
docker compose --profile https up -d    # Start (HTTPS)
docker compose down                     # Stop
docker compose logs -f [service]        # View logs
docker compose restart [service]        # Restart service
docker compose exec db mysqldump -u root -p ips > backup.sql  # Backup DB
```

## Directory Structure

```
ips4-docker-stack/
├── data/
│   ├── ips/           # IPS4 files (place your files here)
│   ├── mysql/         # MySQL data
│   ├── redis/         # Redis data
│   ├── ssl/           # SSL certificates
│   └── certbot/       # Certbot data
├── nginx/             # Nginx configs
├── php/               # PHP-FPM Dockerfile & config
├── mysql/             # MySQL Dockerfile & config
├── redis/             # Redis config
├── scripts/           # Helper scripts
└── docker-compose.yml
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Default nginx page | Ensure IPS4 files are in `data/ips/` |
| Database connection failed | Check `docker compose ps db` and verify `.env` passwords |
| SSL errors | Run `ls -la data/ssl/` to verify certificates exist |
| Port in use | Change `HTTP_PORT` or `HTTPS_PORT` in `.env` |
| Permission denied | Run `sudo chown -R 33:33 data/ips/` (Linux) |

## License

This project is provided as-is for use with Invision Community.
