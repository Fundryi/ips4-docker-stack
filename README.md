# Invision Community 4 (IPS4) Docker Stack

A production-ready Docker stack for **Invision Community 4.x** featuring Nginx, PHP-FPM 8.1, MySQL 8.4 LTS, and Redis 7 for caching.

## Features

- 🐳 **Complete Docker Stack** - Nginx + PHP-FPM + MySQL + Redis
- 🔒 **Host-Mounted Data** - Your data persists even if containers are removed
- ⚡ **Performance Optimized** - Tuned configurations for production workloads
- 🛡️ **Security Hardened** - Security headers and best practices included
- 🔄 **Health Checks** - Built-in health monitoring for all services
- 📦 **Easy Setup** - Simple configuration with sensible defaults
- 🔐 **SSL/HTTPS Support** - Nginx handles SSL directly with your certificates

## Requirements

- Docker Engine 20.10+
- Docker Compose plugin (v2)
- A licensed copy of Invision Community 4.x
- Minimum 4GB RAM (8GB+ recommended for production)

## Quick Start

### 1. Clone or Download

Clone this repository or download files to your server:

```bash
git clone <repository-url> ips4-docker-stack
cd ips4-docker-stack
```

### 2. Configure Environment Variables

Edit [`.env`](.env) file and set strong passwords:

```bash
# Database Configuration
MYSQL_PASSWORD=your_strong_password_here
MYSQL_ROOT_PASSWORD=your_strong_root_password_here

# Port Configuration
HTTP_PORT=80
HTTPS_PORT=443
```

### 3. Copy IPS4 Files

Copy your licensed Invision Community 4 files to data directory:

```bash
# Extract/copy your IPS4 files to:
./data/ips/
```

Verify you have:
```
./data/ips/index.php
```

**Note:** A setup guide page is included at [`data/ips/index.php`](data/ips/index.php) that displays installation instructions when you access the forum before IPS4 is installed. Replace this file with your actual IPS4 files.

### 4. Start the Stack

```bash
docker compose up -d --build
```

### 5. Access Your Forum

**HTTP (works without SSL):**
```
http://your-server-ip/
```

**HTTPS (works when SSL certificates are present):**
```
https://your-server-ip:443/
```

**Note:** The stack starts without SSL certificates. Add certificates to `./data/ssl/` to enable HTTPS.

### 6. Run the Installer

During IPS4 installation, use these database settings:

| Setting | Value |
|---------|-------|
| Database Host | `db` |
| Database Name | `ips` |
| Database User | `ips` |
| Database Password | Value of `MYSQL_PASSWORD` in [`.env`](.env) |

### 7. Enable Redis Caching (Post-Install)

After installation, enable Redis caching in AdminCP:

1. Go to **System → Advanced Configuration → Caching**
2. Set cache method to **Redis**
3. Host: `redis`
4. Port: `6379`

## SSL/HTTPS Setup (Optional)

Nginx handles SSL directly. SSL is optional - the stack works without certificates.

**Without SSL:** Stack starts with HTTP only (port80)
**With SSL:** Place certificates in `./data/ssl/` to enable HTTPS (port443)

### Getting SSL Certificates (Optional)

#### Option 1: Let's Encrypt (Recommended)

1. **Install certbot on your host:**
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install certbot

# CentOS/RHEL
sudo yum install certbot
```

2. **Generate certificates:**
```bash
sudo certbot certonly --webroot -w /var/www/html -d yourdomain.com -d www.yourdomain.com
```

3. **Copy certificates to project:**
```bash
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./data/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./data/ssl/
sudo chown 33:33 ./data/ssl/*.pem
```

#### Option 2: Commercial SSL Certificates

1. Purchase SSL certificate from a provider
2. Download certificate files (fullchain.pem and privkey.pem)
3. Place them in `./data/ssl/`:
   - `fullchain.pem` - Certificate + intermediate chain
   - `privkey.pem` - Private key

### Certificate Renewal

Let's Encrypt certificates need to be renewed. Set up auto-renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Set up auto-renewal (cron job)
sudo crontab -e
# Add this line:
0 0,12 * * * certbot renew --quiet --post-hook "cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /path/to/ips4-docker-stack/data/ssl/ && cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /path/to/ips4-docker-stack/data/ssl/ && chown 33:33 /path/to/ips4-docker-stack/data/ssl/*.pem"
```

### Accessing Your Forum with SSL

After setup, access your forum at:
```
https://your-domain.com
```

## Project Structure

```
ips4-docker-stack/
├── docker-compose.yml       # Docker Compose configuration
├── .env                     # Environment variables (passwords, ports)
├── .env.example             # Environment variables template
├── nginx/
│   └── default.conf         # Nginx configuration (with SSL support)
├── php/
│   ├── Dockerfile           # PHP-FPM 8.1 image definition
│   ├── php.ini              # PHP configuration
│   └── www.conf             # PHP-FPM pool configuration
├── mysql/
│   ├── Dockerfile           # MySQL 8.4 image definition
│   └── my.cnf               # MySQL 8.4 configuration
├── redis/
│   └── redis.conf           # Redis 7 configuration
├── data/
│   ├── ips/                 # Your IPS4 files (mount this)
│   ├── mysql/               # MySQL data (persistent)
│   ├── redis/               # Redis data (persistent)
│   ├── ssl/                 # SSL certificates (fullchain.pem, privkey.pem)
│   └── logs/
│       └── nginx/           # Nginx logs (persistent)
└── README.md                # This file
```

## Configuration

### HTTP/HTTPS Ports

Change ports in [`.env`](.env):

```bash
HTTP_PORT=80   # HTTP - redirects to HTTPS
HTTPS_PORT=443 # HTTPS - main site
```

### MySQL Buffer Pool Size

Adjust MySQL memory usage in [`mysql/my.cnf`](mysql/my.cnf):

| Server RAM | Recommended `innodb_buffer_pool_size` |
|------------|----------------------------------------|
| 16 GB      | 8G - 10G                               |
| 32 GB      | 16G - 20G                              |
| 64 GB      | 32G - 40G                              |

**Note:** After modifying [`mysql/my.cnf`](mysql/my.cnf), rebuild the MySQL image:
```bash
docker compose up -d --build db
```

### PHP-FPM Workers

Adjust PHP-FPM worker count in [`php/www.conf`](php/www.conf):

```ini
pm.max_children = 120  # Lower if running other services
```

### Redis Memory

Adjust Redis memory limit in [`redis/redis.conf`](redis/redis.conf):

```conf
maxmemory 2gb  # Increase for larger forums
```

## Operations

### View Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f nginx
docker compose logs -f php
docker compose logs -f db
docker compose logs -f redis
```

### Stop/Start

```bash
# Stop
docker compose down

# Start
docker compose up -d

# Restart
docker compose restart
```

### Update Images

```bash
docker compose pull
docker compose up -d --build
```

### Backup

```bash
# Back up IPS4 files
tar -czf ips-backup-$(date +%Y%m%d).tar.gz ./data/ips/

# Back up MySQL database
docker compose exec db mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ips > mysql-backup-$(date +%Y%m%d).sql

# Back up Redis (optional - cache only)
tar -czf redis-backup-$(date +%Y%m%d).tar.gz ./data/redis/

# Back up SSL certificates
tar -czf ssl-backup-$(date +%Y%m%d).tar.gz ./data/ssl/
```

### Restore

```bash
# Restore IPS4 files
tar -xzf ips-backup-YYYYMMDD.tar.gz -C ./data/

# Restore MySQL database
docker compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ips < mysql-backup-YYYYMMDD.sql

# Restore SSL certificates
tar -xzf ssl-backup-YYYYMMDD.tar.gz -C ./data/
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker compose logs <service-name>
```

### Database Connection Errors

1. Ensure MySQL is healthy:
```bash
docker compose ps db
```

2. Check database credentials in [`.env`](.env)

3. If MySQL fails to start due to configuration issues, rebuild the image:
```bash
docker compose up -d --build db
```

### SSL Certificate Issues

1. Ensure certificates exist in `./data/ssl/`:
```bash
ls -la ./data/ssl/
# Should show: fullchain.pem, privkey.pem
```

2. Check certificate permissions:
```bash
ls -la ./data/ssl/*.pem
# Should be owned by UID 33 (www-data)
```

3. Fix permissions:
```bash
sudo chown 33:33 ./data/ssl/*.pem
```

### Permission Issues

Ensure proper permissions on data directories:
```bash
# On Linux
sudo chown -R 33:33 ./data/ips
sudo chown -R 33:33 ./data/ssl
```

### High Memory Usage

Reduce MySQL buffer pool size in [`mysql/my.cnf`](mysql/my.cnf) and PHP-FPM workers in [`php/www.conf`](php/www.conf).

## Security Recommendations

1. **Change Default Passwords** - Always use strong passwords in [`.env`](.env)
2. **Use HTTPS** - Set up SSL certificates for production
3. **Firewall** - Restrict access to ports 80/443 (public)
4. **Regular Backups** - Set up automated backups
5. **Update Regularly** - Keep Docker images updated
6. **Certificate Renewal** - Set up auto-renewal for Let's Encrypt certificates

## Production Deployment

For production deployment:

1. Use SSL/HTTPS certificates
2. Set up automated backups
3. Configure monitoring (e.g., Prometheus, Grafana)
4. Use a dedicated database server for larger communities
5. Enable Redis password authentication in [`redis/redis.conf`](redis/redis.conf)

## Support

- [Invision Community Documentation](https://invisioncommunity.com/docs/)
- [Docker Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## License

This Docker stack configuration is provided as-is for use with licensed Invision Community installations.

## Data Safety

All persistent data is stored in the [`./data/`](./data/) directory on your host:

- `./data/ips/` - IPS4 files, uploads, and configuration
- `./data/mysql/` - MySQL database files
- `./data/redis/` - Redis AOF file (cache)
- `./data/ssl/` - SSL certificates

You can safely remove containers and images without losing your data.

## Health Checks

All services include health checks:

- **Nginx**: HTTP endpoint at `/health`
- **PHP-FPM**: Process health check
- **MySQL**: Database ping test
- **Redis**: PING command test

Check service health:
```bash
docker compose ps
```

## Requirements Checker (Optional)

A requirements checker is included in the setup guide. Access it at:

```
http://your-server-ip/ips4.php
```

Or copy the official IPS4 requirements checker to `./data/ips/requirements.php`:

1. Copy `requirements.php` to `./data/ips/`
2. Visit `http://your-server-ip/requirements.php`
3. Delete the file after verification

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
