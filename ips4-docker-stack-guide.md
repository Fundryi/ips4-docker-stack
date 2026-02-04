# IPS4 Docker Stack - Complete Setup Guide

This guide will walk you through setting up Invision Community (IPS4) using Docker Compose.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Configuration](#configuration)
4. [Starting the Stack](#starting-the-stack)
5. [Installing IPS4](#installing-ips4)
6. [SSL/HTTPS Setup](#sslhttps-setup)
7. [Maintenance](#maintenance)
8. [Troubleshooting](#troubleshooting)

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM
- 10GB free disk space

## Initial Setup

### 1. Clone or Download the Project

```bash
cd /path/to/your/projects
# If cloning from git
git clone <repository-url> ips4-docker-stack
cd ips4-docker-stack
```

### 2. Create Environment File

```bash
cp .env.example .env
```

### 3. Prepare IPS4 Files

Place your IPS4 files in the `data/ips/` directory:

```bash
# Create directory if it doesn't exist
mkdir -p data/ips

# Copy or extract IPS4 files to data/ips/
# The structure should look like:
# data/ips/
# ├── index.php
# ├── conf_global.php
# ├── applications/
# ├── system/
# └── ... (other IPS4 files)
```

## Configuration

### Edit .env File

Open `.env` in your editor and configure:

```bash
# Database Configuration
MYSQL_PASSWORD=your_secure_password_here
MYSQL_ROOT_PASSWORD=your_secure_root_password_here

# Port Configuration
HTTP_PORT=80
HTTPS_PORT=443

# SSL Configuration
SSL_ENABLED=false
```

**Important**: Use strong, unique passwords for production use.

### Database Settings

The stack uses these default database settings:

- **Host**: `db`
- **Database**: `ips`
- **User**: `ips`
- **Password**: (set in `MYSQL_PASSWORD`)

These are configured in the PHP container and don't need to be changed.

## Starting the Stack

### Start HTTP Only (Default)

```bash
docker compose up -d
```

This will start:
- MySQL database
- Redis cache
- PHP-FPM
- Nginx (HTTP only)

### Start with HTTPS

```bash
docker compose --profile https up -d
```

This will start all services plus the HTTPS nginx service.

### Check Status

```bash
docker compose ps
```

All services should show "Up" or "healthy".

## Installing IPS4

### 1. Access the Installer

Open your browser and navigate to:
- HTTP: `http://localhost` (or your configured `HTTP_PORT`)

### 2. Run the Installer

Follow the IPS4 installation wizard:

1. **System Requirements**: Click "Continue"
2. **Database Information**:
   - Database Server: `db`
   - Database Name: `ips`
   - Database Username: `ips`
   - Database Password: (your `MYSQL_PASSWORD`)
   - Table Prefix: (leave empty or use `ips_`)
3. **Admin Account**: Create your admin credentials
4. **Configuration**: Review and confirm settings

### 3. Complete Installation

After installation, remove the install files:

```bash
rm -rf data/ips/install/
```

## SSL/HTTPS Setup

### Option 1: Using Let's Encrypt (Recommended)

1. **Generate Certificates**:

```bash
# Stop the stack temporarily
docker compose down

# Use certbot to generate certificates
certbot certonly --standalone -d yourdomain.com -d www.yourdomain.com
```

2. **Copy Certificates**:

```bash
mkdir -p data/ssl
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem data/ssl/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem data/ssl/
```

3. **Enable HTTPS in .env**:

```bash
SSL_ENABLED=true
```

4. **Start with HTTPS**:

```bash
docker compose --profile https up -d
```

### Option 2: Using Existing Certificates

If you have certificates from another source:

1. **Copy Certificates**:

```bash
mkdir -p data/ssl
cp /path/to/your/fullchain.pem data/ssl/
cp /path/to/your/privkey.pem data/ssl/
```

2. **Enable HTTPS**:

```bash
SSL_ENABLED=true
```

3. **Restart with HTTPS**:

```bash
docker compose down
docker compose --profile https up -d
```

### Option 3: Self-Signed Certificates (Testing Only)

For local testing, you can generate self-signed certificates:

```bash
mkdir -p data/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout data/ssl/privkey.pem \
  -out data/ssl/fullchain.pem \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
```

Then enable HTTPS as above.

## Maintenance

### Updating IPS4

1. **Backup your data**:
```bash
docker compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ips > backup.sql
```

2. **Upload new IPS4 files** to `data/ips/`

3. **Run the upgrader** by visiting `http://yourdomain.com/admin/upgrade`

### Viewing Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f nginx
docker compose logs -f php
docker compose logs -f db
```

### Restarting Services

```bash
# All services
docker compose restart

# Specific service
docker compose restart nginx
```

### Updating Docker Images

```bash
docker compose pull
docker compose up -d
```

### Backups

Regular backups are essential:

```bash
# Database backup
docker compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ips > backup-$(date +%Y%m%d).sql

# Files backup
tar -czf ips-files-$(date +%Y%m%d).tar.gz data/ips/
```

## Troubleshooting

### Nginx Shows Default Page

**Problem**: You see the "Welcome to nginx!" page instead of IPS4.

**Solution**: Ensure your IPS4 files are in `data/ips/`:

```bash
ls -la data/ips/
# Should show index.php, conf_global.php, etc.
```

### Database Connection Failed

**Problem**: IPS4 can't connect to the database.

**Solution**:
1. Check MySQL is running:
```bash
docker compose ps db
```

2. Check MySQL logs:
```bash
docker compose logs db
```

3. Verify database credentials in `.env`

### SSL Certificate Errors

**Problem**: HTTPS nginx fails to start with certificate errors.

**Solution**:
1. Verify certificates exist:
```bash
ls -la data/ssl/
# Should show fullchain.pem and privkey.pem
```

2. Check certificate permissions:
```bash
chmod 644 data/ssl/fullchain.pem
chmod 600 data/ssl/privkey.pem
```

3. Verify certificates are valid:
```bash
openssl x509 -in data/ssl/fullchain.pem -text -noout
```

### Port Already in Use

**Problem**: Port 80 or 443 is already in use.

**Solution**: Change the port in `.env`:

```bash
HTTP_PORT=8080
HTTPS_PORT=8443
```

Then restart:
```bash
docker compose down
docker compose up -d
```

### Permission Issues

**Problem**: Files can't be written by PHP.

**Solution**: Fix permissions:

```bash
# On Linux
sudo chown -R 33:33 data/ips/
# (33 is the www-data user ID in the PHP container)
```

### Health Checks Failing

**Problem**: Services keep restarting.

**Solution**:
1. Check logs for the failing service:
```bash
docker compose logs <service-name>
```

2. Ensure all dependencies are healthy:
```bash
docker compose ps
```

## Additional Resources

- [IPS4 Documentation](https://invisioncommunity.com/documentation/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## Support

For issues specific to this Docker stack, please check the troubleshooting section above or open an issue in the project repository.

For IPS4-specific issues, please refer to the [Invision Community Forums](https://invisioncommunity.com/forums/).
