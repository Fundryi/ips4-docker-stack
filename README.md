# IPS4 Docker Stack

A complete Docker Compose setup for Invision Community (IPS4) with MySQL, Redis, PHP-FPM, and Nginx.

## Features

- **IPS4**: Full Invision Community support
- **MySQL**: Database backend
- **Redis**: Caching layer
- **PHP-FPM**: PHP 8.x with required extensions
- **Nginx**: Web server with HTTP and HTTPS support
- **Certbot**: Automatic SSL certificate renewal with Let's Encrypt
- **Docker Compose Profiles**: Simple SSL enable/disable via profile flag

## Quick Start

### 1. Clone and Setup

```bash
# Copy the example environment file
cp .env.example .env

# Edit .env with your settings
nano .env
```

### 2. Configure Environment

Edit `.env` and set your database passwords:

```bash
MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_secure_root_password
```

### 3. Start the Stack

```bash
# Start all services (HTTP only)
docker compose up -d

# Or start with HTTPS enabled
docker compose --profile https up -d
```

### 4. Access Your Site

- **HTTP**: `http://localhost` (or your configured `HTTP_PORT`)
- **HTTPS**: `https://localhost` (or your configured `HTTPS_PORT`, when enabled)

## SSL/HTTPS Configuration

### Initial SSL Setup with Let's Encrypt

**Option A: Use the helper script (recommended)**:

```bash
chmod +x scripts/init-ssl.sh
./scripts/init-ssl.sh yourdomain.com your@email.com
docker compose --profile https up -d
```

**Option B: Manual setup**:

1. Create required directories:

```bash
mkdir -p data/ssl data/certbot/www data/certbot/logs
```

2. Start HTTP nginx for ACME challenge:

```bash
docker compose up -d nginx
```

3. Request certificate:

```bash
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your@email.com \
  --agree-tos \
  --no-eff-email \
  -d yourdomain.com
```

4. Create certificate symlinks:

```bash
docker compose down
ln -sf live/yourdomain.com/fullchain.pem data/ssl/fullchain.pem
ln -sf live/yourdomain.com/privkey.pem data/ssl/privkey.pem
```

5. Start with HTTPS:

```bash
docker compose --profile https up -d
```

### Automatic Certificate Renewal

When running with the `https` profile, certificate renewal is fully automated:

- **certbot** container checks for renewal once daily
- **nginx-reload** container reloads nginx daily to pick up renewed certificates
- Certificates are only renewed within 30 days of expiry (respects Let's Encrypt rate limits)

To manually trigger a renewal:

```bash
docker compose exec certbot certbot renew
docker compose kill -s HUP nginx-https
```

### Disabling HTTPS

To switch back to HTTP only:

```bash
docker compose down
docker compose up -d
```

## Directory Structure

```
ips4-docker-stack/
├── data/
│   ├── ips/          # IPS4 application files (mount your IPS4 here)
│   ├── mysql/        # MySQL data persistence
│   ├── redis/        # Redis data persistence
│   ├── ssl/          # SSL certificates (symlinks to Let's Encrypt certs)
│   ├── certbot/      # Certbot data
│   │   ├── www/      # ACME challenge webroot
│   │   └── logs/     # Certbot logs
│   └── logs/         # Application logs
│       ├── nginx/
│       └── php/
├── nginx/
│   ├── http.conf     # HTTP-only nginx configuration
│   └── https.conf    # HTTPS nginx configuration
├── php/
│   └── Dockerfile    # PHP-FPM custom image
├── redis/
│   └── redis.conf    # Redis configuration
├── .env              # Environment variables (create from .env.example)
├── .env.example      # Environment variables template
└── docker-compose.yml
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MYSQL_PASSWORD` | `change_me_to_strong_password` | MySQL user password |
| `MYSQL_ROOT_PASSWORD` | `change_me_to_strong_root_password` | MySQL root password |
| `HTTP_PORT` | `80` | HTTP port |
| `HTTPS_PORT` | `443` | HTTPS port |
| `DOMAIN` | `example.com` | Your domain name (for SSL) |
| `CERTBOT_EMAIL` | `admin@example.com` | Email for Let's Encrypt notifications |

## Common Commands

```bash
# Start services
docker compose up -d

# Start with HTTPS
docker compose --profile https up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# View logs for specific service
docker compose logs -f nginx

# Restart a service
docker compose restart nginx
```

## Troubleshooting

### Nginx shows default page instead of IPS4

Make sure your IPS4 files are in the correct location:
```
data/ips/
├── index.php
├── conf_global.php
└── ... (other IPS4 files)
```

### SSL Certificate Errors

If you see certificate errors when starting HTTPS:

1. Ensure certificates exist in `data/ssl/`:
   - `fullchain.pem` (or symlink to `live/yourdomain.com/fullchain.pem`)
   - `privkey.pem` (or symlink to `live/yourdomain.com/privkey.pem`)

2. Check symlinks are correct:
```bash
ls -la data/ssl/
```

3. Verify Let's Encrypt certificates exist:
```bash
ls -la data/ssl/live/yourdomain.com/
```

### Certificate Renewal Issues

Check certbot logs:
```bash
docker compose logs certbot
cat data/certbot/logs/letsencrypt.log
```

Manually test renewal:
```bash
docker compose exec certbot certbot renew --dry-run
```

### Database Connection Issues

Check that MySQL is healthy:
```bash
docker compose ps
```

If MySQL is restarting, check the logs:
```bash
docker compose logs db
```

## License

This project is provided as-is for use with Invision Community.
