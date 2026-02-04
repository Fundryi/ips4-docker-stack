# Invision Community 4 (IPS4) Docker Stack

A production-ready Docker stack for **Invision Community 4.x** featuring Nginx, PHP-FPM 8.1, MySQL 8.4 LTS, and Redis 7 for caching.

## Features

- 🐳 **Complete Docker Stack** - Nginx + PHP-FPM + MySQL + Redis
- 🔒 **Host-Mounted Data** - Your data persists even if containers are removed
- ⚡ **Performance Optimized** - Tuned configurations for production workloads
- 🛡️ **Security Hardened** - Security headers and best practices included
- 🔄 **Health Checks** - Built-in health monitoring for all services
- 📦 **Easy Setup** - Simple configuration with sensible defaults
- 🔐 **Optional SSL/HTTPS** - Automatic Let's Encrypt certificates with Nginx Proxy Manager

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
# Docker Compose Profiles
# Set to "proxy" to enable reverse proxy with SSL/HTTPS
# Leave empty for HTTP only mode
COMPOSE_PROFILES=

# Database Configuration
MYSQL_PASSWORD=your_strong_password_here
MYSQL_ROOT_PASSWORD=your_strong_root_password_here

# HTTP Port Configuration
HTTP_PORT=8080

# Reverse Proxy Configuration (Optional)
PROXY_HTTP_PORT=80
PROXY_HTTPS_PORT=443
PROXY_UI_PORT=81
PROXY_EMAIL=admin@example.com
PROXY_PASSWORD=changeme
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_EMAIL=
```

For SSL/HTTPS setup, see [SSL/HTTPS Setup](#sslhttps-setup-optional) section below.

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

Open your browser and navigate to:

```
http://your-server-ip:8080/
```

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

For production deployment with automatic SSL certificates and HTTPS, use the reverse proxy service with **Nginx Proxy Manager**.

### Why Use a Proxy?

- 🔒 **Automatic SSL Certificates** - Let's Encrypt with auto-renewal
- 🎛️ **Web UI Management** - Easy-to-use interface for configuration
- ☁️ **Cloudflare Support** - DNS challenge for wildcard certificates
- 🔄 **Zero Downtime** - Seamless certificate renewal
- 📦 **Simple Setup** - Configure ports in [`.env`](.env) file

### Quick Setup with SSL

1. **Configure Environment Variables:**

Edit [`.env`](.env) file and set your proxy configuration:

```bash
# Enable the reverse proxy
COMPOSE_PROFILES=proxy

# Configure public ports
PROXY_HTTP_PORT=80
PROXY_HTTPS_PORT=443
PROXY_UI_PORT=81

# Proxy Manager credentials (CHANGE AFTER FIRST LOGIN!)
PROXY_EMAIL=admin@example.com
PROXY_PASSWORD=changeme

# Cloudflare DNS Challenge (optional - for wildcard certificates)
CLOUDFLARE_API_TOKEN=your_api_token_here
CLOUDFLARE_EMAIL=your_cloudflare_email@example.com
```

2. **Start the stack:**

```bash
docker compose up -d --build
```

The proxy service will automatically start because `COMPOSE_PROFILES=proxy` is set in your `.env` file.

3. **Access a Proxy Manager UI:**

Open `http://your-server-ip:81` in your browser.

4. **Default Login Credentials:**

```
Email:    admin@example.com
Password: changeme
```

⚠️ **Important:** Change default password immediately after first login!

5. **Add Your Domain:**

1. Go to **Hosts → Proxy Hosts**
2. Click **Add Proxy Host**
3. Fill in:
   - **Domain Names**: `your-domain.com` (and `www.your-domain.com`)
   - **Scheme**: `http`
   - **Forward Hostname**: `nginx` (the container name)
   - **Forward Port**: `80`
4. Click **Save**

6. **Enable SSL:**

1. In the same Proxy Host configuration, go to the **SSL** tab
2. Select **Request a new SSL Certificate**
3. Enable:
   - ✅ Force SSL
   - ✅ HTTP/2 Support
   - ✅ HSTS Enabled
4. For Cloudflare users, use **DNS Challenge**:
   - Select **DNS Challenge**
   - Choose **Cloudflare**
   - Enter your Cloudflare API Token
5. Click **Save**

### Cloudflare DNS Challenge Setup

For wildcard certificates (`*.your-domain.com`), use Cloudflare DNS challenge:

1. **Get Cloudflare API Token:**
   - Go to Cloudflare Dashboard → My Profile → API Tokens
   - Create token with **Zone → DNS → Edit** permissions
   - Copy the token

2. **Configure in Proxy Manager:**
   - In SSL tab, select **DNS Challenge**
   - Choose **Cloudflare** as provider
   - Paste your API Token
   - Enter your Cloudflare email

3. **Request Certificate:**
   - Enter domain: `*.your-domain.com`
   - Click **Save**

### Accessing Your Forum

After setup, access your forum at:

```
https://your-domain.com
```

### Proxy Manager Ports

| Port | Purpose |
|-------|---------|
| 80    | HTTP (public) |
| 443   | HTTPS (public) |
| 81    | Management UI (internal - restrict access!) |

### Switching Between Configurations

Simply edit the `COMPOSE_PROFILES` variable in your [`.env`](.env) file:

- **Without SSL (HTTP only):** Set `COMPOSE_PROFILES=` (empty)
- **With SSL (HTTPS):** Set `COMPOSE_PROFILES=proxy`

Then restart the stack:
```bash
docker compose down
docker compose up -d --build
```

## Project Structure

```
ips4-docker-stack/
├── docker-compose.yml       # Docker Compose configuration (includes proxy service)
├── .env                     # Environment variables (passwords, ports)
├── .env.example             # Environment variables template
├── nginx/
│   └── default.conf         # Nginx configuration
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
│   ├── proxy/               # Proxy manager data (persistent)
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

3. If MySQL fails to start due to configuration issues, rebuild the image:
```bash
docker compose up -d --build db
```

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
2. **Use HTTPS** - Set `COMPOSE_PROFILES=proxy` in [`.env`](.env) for automatic SSL certificates
3. **Firewall** - Restrict access to ports 80/443 (public) and 81 (proxy UI - internal only!)
4. **Regular Backups** - Set up automated backups
5. **Update Regularly** - Keep Docker images updated
6. **Proxy UI Security** - Change default Nginx Proxy Manager password immediately

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
- `./data/proxy/` - Nginx Proxy Manager data and SSL certificates

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
http://your-server-ip:8080/ips4.php
```

Or copy the official IPS4 requirements checker to `./data/ips/requirements.php`:

1. Copy `requirements.php` to `./data/ips/`
2. Visit `http://your-server-ip:8080/requirements.php`
3. Delete the file after verification

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
