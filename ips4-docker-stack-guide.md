# Invision Community 4 (IPS4) Docker Stack (Nginx + PHP-FPM + MySQL 8.4 + Redis)

This guide sets up a production-grade Docker stack for **Invision Community 4.x** using:

- Nginx only (no Apache)
- PHP-FPM 8.1 (latest compatible major for IPS4)
- MySQL 8.4 LTS
- Redis 7 for caching
- Host-mounted data so deleting containers does not delete your forum data
- SSL/HTTPS support via Nginx

## What you need

- A Linux host with Docker + Docker Compose plugin installed
- Your licensed Invision Community 4 files
- Ports:
  - 80 exposes HTTP (redirects to HTTPS)
  - 443 exposes HTTPS (main site)

## Folder layout

You will create this structure:

```text
ips-docker/
  docker-compose.yml
  .env
  nginx/default.conf
  php/Dockerfile
  php/php.ini
  php/www.conf
  mysql/my.cnf
  redis/redis.conf
  data/
    ips/
    mysql/
    redis/
    ssl/
    logs/nginx/
```

## 1) Create folders

```bash
mkdir -p ips-docker/{nginx,php,mysql,redis,data/ips,data/mysql,data/redis,data/ssl,data/logs/nginx}
cd ips-docker
```

Copy/extract your Invision Community 4 files into:

```text
./data/ips/
```

Verify you have:

```text
./data/ips/index.php
```

## 2) Create .env (DB passwords + ports)

Create `ips-docker/.env`:

```bash
# Database Configuration
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me_root

# Port Configuration
HTTP_PORT=80
HTTPS_PORT=443
```

Use strong passwords.

## 3) Start the stack

From `ips-docker/`:

```bash
docker compose up -d --build
```

Open:

```text
http://SERVER-IP:80/  # Redirects to HTTPS
https://SERVER-IP:443/  # Main site with HTTPS
```

**Note:** Without SSL certificates, HTTPS will show a warning. See SSL setup below.

## 4) SSL/HTTPS Setup (Optional but Recommended)

Nginx handles SSL directly. You need to provide your SSL certificates.

### Getting SSL Certificates

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

4. **Restart nginx:**
```bash
docker compose restart nginx
```

#### Option 2: Commercial SSL Certificates

1. Purchase SSL certificate from a provider
2. Download certificate files (fullchain.pem and privkey.pem)
3. Place them in `./data/ssl/`:
   - `fullchain.pem` - Certificate + intermediate chain
   - `privkey.pem` - Private key

4. **Restart nginx:**
```bash
docker compose restart nginx
```

### Certificate Renewal

Let's Encrypt certificates need to be renewed. Set up auto-renewal:

```bash
# Test renewal
sudo certbot renew --dry-run

# Set up auto-renewal (cron job)
sudo crontab -e
# Add this line:
0 0,12 * * * certbot renew --quiet --post-hook "cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem /path/to/ips-docker/data/ssl/ && cp /etc/letsencrypt/live/yourdomain.com/privkey.pem /path/to/ips-docker/data/ssl/ && chown 33:33 /path/to/ips-docker/data/ssl/*.pem"
```

## 5) Build a PHP-FPM image (PHP 8.1 + extensions + Redis extension)

### 5.1 php/Dockerfile

Create `ips-docker/php/Dockerfile`:

```dockerfile
FROM php:8.1-fpm-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends     libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev     libxml2-dev   && docker-php-ext-configure gd --with-freetype --with-jpeg   && docker-php-ext-install -j"$(nproc)"     intl mbstring mysqli pdo_mysql zip gd exif opcache   && pecl install redis   && docker-php-ext-enable redis   && rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/99-ips.ini
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
```

### 5.2 php/php.ini

Create `ips-docker/php/php.ini`:

```ini
memory_limit=1024M
upload_max_filesize=512M
post_max_size=512M
max_execution_time=300
max_input_vars=20000

realpath_cache_size=8192K
realpath_cache_ttl=600

opcache.enable=1
opcache.enable_cli=0
opcache.memory_consumption=512
opcache.interned_strings_buffer=32
opcache.max_accelerated_files=100000
opcache.validate_timestamps=1
opcache.revalidate_freq=10
opcache.jit=0
```

### 5.3 php/www.conf (PHP-FPM performance)

Create `ips-docker/php/www.conf`:

```ini
[www]
user = www-data
group = www-data
listen = 9000

pm = dynamic
pm.max_children = 120
pm.start_servers = 16
pm.min_spare_servers = 16
pm.max_spare_servers = 32
pm.max_requests = 800

request_terminate_timeout = 300
catch_workers_output = yes
```

Note: these values assume a strong server and IPS is a main workload. If you run lots of other services, lower `pm.max_children`.

## 6) Nginx config (IPS4 friendly URLs + SSL + static caching)

Create `ips-docker/nginx/default.conf`:

```nginx
# HTTP Server - Redirect to HTTPS
server {
  listen 80;
  server_name _;
  return 301 https://$host$request_uri;
}

# HTTPS Server
server {
  listen 443 ssl http2;
  server_name _;
  root /var/www/html;
  index index.php index.html;

  client_max_body_size 512m;

  # SSL Configuration
  ssl_certificate /etc/nginx/ssl/fullchain.pem;
  ssl_certificate_key /etc/nginx/ssl/privkey.pem;
  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers HIGH:!aNULL:!MD5;
  ssl_prefer_server_ciphers on;
  ssl_session_cache shared:SSL:10m;
  ssl_session_timeout 10m;

  # Security headers
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
  add_header X-Frame-Options "SAMEORIGIN" always;
  add_header X-Content-Type-Options "nosniff" always;
  add_header X-XSS-Protection "1; mode=block" always;
  add_header Referrer-Policy "strict-origin-when-cross-origin" always;

  # Gzip compression
  gzip on;
  gzip_vary on;
  gzip_min_length 1024;
  gzip_types
    text/plain
    text/css
    text/xml
    text/javascript
    application/json
    application/javascript
    application/xml+rss
    application/rss+xml
    application/atom+xml
    image/svg+xml;

  # IPS4 friendly URLs
  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  # PHP-FPM handling
  location ~ \.php$ {
    try_files $uri =404;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass php:9000;
    fastcgi_read_timeout 300;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;
  }

  # Static file caching
  location ~* \.(?:css|js|jpg|jpeg|gif|png|webp|svg|ico|woff2?|ttf|eot)$ {
    expires 30d;
    access_log off;
    add_header Cache-Control "public, immutable";
    try_files $uri =404;
  }

  # Deny access to hidden files (except .well-known)
  location ~ /\.(?!well-known) {
    deny all;
    access_log off;
    log_not_found off;
  }

  # Health check endpoint
  location /health {
    access_log off;
    return 200 "healthy\n";
    add_header Content-Type text/plain;
  }
}
```

## 7) MySQL 8.4 tuning

Create `ips-docker/mysql/my.cnf`:

```ini
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

innodb_flush_method=O_DIRECT
innodb_flush_log_at_trx_commit=2
innodb_file_per_table=1
innodb_log_buffer_size=64M
innodb_redo_log_capacity=4G

# Tune this to about 60% of RAM if the box is mostly IPS
innodb_buffer_pool_size=16G
innodb_buffer_pool_instances=8

max_connections=600
table_open_cache=12000
table_definition_cache=6000
thread_cache_size=200

tmp_table_size=512M
max_heap_table_size=512M

slow_query_log=1
long_query_time=1
```

Quick sizing:
- 16 GB RAM: 8G to 10G
- 32 GB RAM: 16G to 20G
- 64 GB RAM: 32G to 40G

## 8) Redis tuning (cache + durable AOF)

Create `ips-docker/redis/redis.conf`:

```conf
appendonly yes
appendfsync everysec
save ""

maxmemory 2gb
maxmemory-policy allkeys-lru

tcp-keepalive 60
timeout 0
databases 1
```

Adjust `maxmemory` depending on RAM and forum size.

## 9) IPS4 Installation

After starting the stack, access your forum at:
```text
https://SERVER-IP:443/
```

Installer values:
- DB host: db
- DB name: ips
- DB user: ips
- DB pass: value of MYSQL_PASSWORD in .env

## 10) Enable Redis in IPS (after install)

In AdminCP, set caching to Redis:
- Host: redis
- Port: 6379

## 11) Requirements checker (optional but recommended)

Copy the IPS requirements checker into the web root, for example:

```text
./data/ips/requirements.php
```

Open:

```text
https://SERVER-IP:443/requirements.php
```

Delete it afterwards:

```bash
rm ./data/ips/requirements.php
```

## Data safety

All persistent data lives on the host:

- ./data/mysql (database)
- ./data/redis (Redis AOF)
- ./data/ips (forum files, uploads, config)
- ./data/ssl (SSL certificates)

You can remove containers and images and your data stays.

## Ops cheatsheet

View logs:
```bash
docker compose logs -f nginx
docker compose logs -f php
docker compose logs -f db
docker compose logs -f redis
```

Stop/start:
```bash
docker compose down
docker compose up -d
```

Update images (keeps data and configs):
```bash
docker compose pull
docker compose up -d
```

Backup:
- Back up ./data/ips
- Back up ./data/mysql (or use mysqldump)
- Back up ./data/ssl (SSL certificates)
- Redis is cache, but AOF is in ./data/redis if you want it
