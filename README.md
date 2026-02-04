# IPS4 Docker Stack

A complete Docker Compose setup for Invision Community (IPS4) with MySQL, Redis, PHP-FPM, and Nginx.

## Features

- **IPS4**: Full Invision Community support
- **MySQL**: Database backend
- **Redis**: Caching layer
- **PHP-FPM**: PHP 8.x with required extensions
- **Nginx**: Web server with HTTP and HTTPS support
- **Docker Compose Profiles**: Simple SSL enable/disable via environment variable

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

### Enabling HTTPS

1. **Generate SSL Certificates** (using certbot or similar):

```bash
# Example using certbot
certbot certonly --standalone -d yourdomain.com

# Certificates will be in /etc/letsencrypt/live/yourdomain.com/
```

2. **Copy Certificates** to the project:

```bash
# Create SSL directory
mkdir -p data/ssl

# Copy certificates
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem data/ssl/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem data/ssl/
```

3. **Enable HTTPS** in `.env`:

```bash
SSL_ENABLED=true
```

4. **Restart with HTTPS profile**:

```bash
docker compose down
docker compose --profile https up -d
```

### Disabling HTTPS

Set `SSL_ENABLED=false` in `.env` and restart:

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
│   ├── ssl/          # SSL certificates (for HTTPS)
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
| `SSL_ENABLED` | `false` | Enable HTTPS profile |

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
   - `fullchain.pem`
   - `privkey.pem`

2. Check file permissions:
```bash
chmod 644 data/ssl/fullchain.pem
chmod 600 data/ssl/privkey.pem
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
