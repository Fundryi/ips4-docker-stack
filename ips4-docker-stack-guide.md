# IPS4 Docker Stack - Installation Guide

Complete walkthrough for deploying Invision Community 4 with Docker.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- 2GB+ RAM, 10GB+ disk space
- IPS4 license and files

## Step 1: Initial Setup

```bash
# Clone/download the project
git clone <repository-url> ips4-docker-stack
cd ips4-docker-stack

# Create environment file
cp .env.example .env
```

## Step 2: Configure Environment

Edit `.env` with secure passwords:

```bash
MYSQL_PASSWORD=your_secure_password
MYSQL_ROOT_PASSWORD=your_secure_root_password
HTTP_PORT=80
HTTPS_PORT=443
```

## Step 3: Add IPS4 Files

Extract your IPS4 files to `data/ips/`:

```
data/ips/
├── index.php
├── applications/
├── system/
└── uploads/
```

## Step 4: Start Services

```bash
# HTTP only
docker compose up -d

# With HTTPS (after SSL setup)
docker compose --profile https up -d
```

Verify all services are running:

```bash
docker compose ps
```

## Step 5: Install IPS4

1. Open `http://your-server-ip` in browser
2. Follow the installation wizard
3. Database settings:

| Setting | Value |
|---------|-------|
| Host | `db` |
| Database | `ips` |
| Username | `ips` |
| Password | Your `MYSQL_PASSWORD` |

4. Complete setup and create admin account
5. Delete installer: `rm -rf data/ips/install/`

## Step 6: Enable Redis (Recommended)

In AdminCP, go to **System > Advanced Configuration > Caching**:

| Setting | Value |
|---------|-------|
| Method | Redis |
| Host | `redis` |
| Port | `6379` |

## Step 7: SSL Setup (Production)

### Option A: Automated Script

```bash
./scripts/init-ssl.sh yourdomain.com your@email.com
docker compose --profile https up -d
```

### Option B: Manual

```bash
mkdir -p data/ssl data/certbot/www data/certbot/logs
docker compose up -d nginx

docker compose run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email your@email.com --agree-tos --no-eff-email \
  -d yourdomain.com

docker compose down
ln -sf live/yourdomain.com/fullchain.pem data/ssl/fullchain.pem
ln -sf live/yourdomain.com/privkey.pem data/ssl/privkey.pem
docker compose --profile https up -d
```

### Option C: Self-Signed (Testing)

```bash
mkdir -p data/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout data/ssl/privkey.pem -out data/ssl/fullchain.pem \
  -subj "/CN=localhost"
docker compose --profile https up -d
```

## Maintenance

### Backups

```bash
# Database
docker compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ips > backup.sql

# Files
tar -czf ips-files-backup.tar.gz data/ips/
```

### Updates

```bash
# Update IPS4: upload new files to data/ips/, then visit /admin/upgrade

# Update Docker images
docker compose pull && docker compose up -d
```

### Logs

```bash
docker compose logs -f          # All services
docker compose logs -f nginx    # Specific service
```

## Troubleshooting

### Database Connection Failed

```bash
docker compose ps db           # Check if running
docker compose logs db         # Check logs
```

### Permission Issues (Linux)

```bash
sudo chown -R 33:33 data/ips/  # www-data user
```

### SSL Certificate Issues

```bash
ls -la data/ssl/                              # Check files exist
docker compose logs certbot                   # Check certbot logs
docker compose exec certbot certbot renew --dry-run  # Test renewal
```

### Port Conflicts

Edit `.env`:

```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```

## Resources

- [IPS4 Documentation](https://invisioncommunity.com/documentation/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
