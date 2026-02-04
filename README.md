# Invision Community 4 (IPS4) Docker Stack

A production-ready Docker stack for **Invision Community 4.x** featuring Nginx, PHP-FPM 8.1, MySQL 8.4 LTS, and Redis 7 for caching.

## Features

- 🐳 **Complete Docker Stack** - Nginx + PHP-FPM + MySQL + Redis
- 🔒 **Host-Mounted Data** - Your data persists even if containers are removed
- ⚡ **Performance Optimized** - Tuned configurations for production workloads
- 🛡️ **Security Hardened** - Security headers and best practices included
- 🔄 **Health Checks** - Built-in health monitoring for all services
- 📦 **Easy Setup** - Simple configuration with sensible defaults

## Requirements

- Docker Engine 20.10+
- Docker Compose plugin (v2)
- A licensed copy of Invision Community 4.x
- Minimum 4GB RAM (8GB+ recommended for production)

## Quick Start

### 1. Clone or Download

Clone this repository or download the files to your server:

```bash
git clone <repository-url> ips4-docker-stack
cd ips4-docker-stack
```

### 2. Configure Environment Variables

Edit the [`.env`](.env) file and set strong passwords:

```bash
MYSQL_PASSWORD=your_strong_password_here
MYSQL_ROOT_PASSWORD=your_strong_root_password_here
HTTP_PORT=8080
```

### 3. Copy IPS4 Files

Copy your licensed Invision Community 4 files to the data directory:

```bash
# Extract/copy your IPS4 files to:
./data/ips/
```

Verify you have:
```
./data/ips/index.php
```

### 4. Start the Stack

```bash
docker compose up -d --build
```

### 5. Access Your Forum

Open your browser and navigate to:

```
http://your-server-ip:8080/
```

### 6. Run the Installer

During the IPS4 installation, use these database settings:

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

## Project Structure

```
ips4-docker-stack/
├── docker-compose.yml       # Main Docker Compose configuration
├── .env                     # Environment variables (passwords, ports)
├── nginx/
│   └── default.conf         # Nginx configuration
├── php/
│   ├── Dockerfile           # PHP-FPM 8.1 image definition
│   ├── php.ini              # PHP configuration
│   └── www.conf             # PHP-FPM pool configuration
├── mysql/
│   └── my.cnf               # MySQL 8.4 configuration
├── redis/
│   └── redis.conf           # Redis 7 configuration
├── data/
│   ├── ips/                 # Your IPS4 files (mount this)
│   ├── mysql/               # MySQL data (persistent)
│   ├── redis/               # Redis data (persistent)
│   └── logs/
│       └── nginx/           # Nginx logs (persistent)
└── README.md                # This file
```

## Configuration

### HTTP Port

Change the HTTP port in [`.env`](.env):

```bash
HTTP_PORT=8080  # Change to 80 for production with reverse proxy
```

### MySQL Buffer Pool Size

Adjust MySQL memory usage in [`mysql/my.cnf`](mysql/my.cnf):

| Server RAM | Recommended `innodb_buffer_pool_size` |
|------------|----------------------------------------|
| 16 GB      | 8G - 10G                               |
| 32 GB      | 16G - 20G                              |
| 64 GB      | 32G - 40G                              |

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
```

### Restore

```bash
# Restore IPS4 files
tar -xzf ips-backup-YYYYMMDD.tar.gz -C ./data/

# Restore MySQL database
docker compose exec -T db mysql -u root -p${MYSQL_ROOT_PASSWORD} ips < mysql-backup-YYYYMMDD.sql
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

### Permission Issues

Ensure proper permissions on data directories:
```bash
# On Linux
sudo chown -R 33:33 ./data/ips
```

### High Memory Usage

Reduce MySQL buffer pool size in [`mysql/my.cnf`](mysql/my.cnf) and PHP-FPM workers in [`php/www.conf`](php/www.conf).

## Security Recommendations

1. **Change Default Passwords** - Always use strong passwords in [`.env`](.env)
2. **Use HTTPS** - Place behind a reverse proxy with SSL/TLS (e.g., Traefik, Nginx Proxy Manager)
3. **Firewall** - Restrict access to port 8080
4. **Regular Backups** - Set up automated backups
5. **Update Regularly** - Keep Docker images updated

## Production Deployment

For production deployment:

1. Use a reverse proxy with SSL/TLS termination
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

For pre-installation verification, you can use the IPS4 requirements checker:

1. Copy `requirements.php` to `./data/ips/`
2. Visit `http://your-server-ip:8080/requirements.php`
3. Delete the file after verification

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
