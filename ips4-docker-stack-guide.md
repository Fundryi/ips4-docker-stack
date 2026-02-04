# Invision Community 4 (IPS4) Docker Stack (Nginx + PHP-FPM + MySQL 8.4 + Redis)

This guide sets up a production-grade Docker stack for **Invision Community 4.x** using:

- Nginx only (no Apache)
- PHP-FPM 8.1 (latest compatible major for IPS4)
- MySQL 8.4 LTS
- Redis 7 for caching
- Host-mounted data so deleting containers does not delete your forum data

## What you need

- A Linux host with Docker + Docker Compose plugin installed
- Your licensed Invision Community 4 files
- Ports:
  - 8080 exposes the forum (change if you want)

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
    logs/nginx/
```

## 1) Create folders

```bash
mkdir -p ips-docker/{nginx,php,mysql,redis,data/ips,data/mysql,data/redis,data/logs/nginx}
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

## 2) Create docker-compose.yml

Create `ips-docker/docker-compose.yml`:

```yaml
services:
  db:
    image: mysql:8.4
    command: ["mysqld", "--defaults-file=/etc/mysql/conf.d/my.cnf"]
    environment:
      MYSQL_DATABASE: ips
      MYSQL_USER: ips
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - ./data/mysql:/var/lib/mysql
      - ./mysql/my.cnf:/etc/mysql/conf.d/my.cnf:ro
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: ["redis-server", "/usr/local/etc/redis/redis.conf"]
    volumes:
      - ./data/redis:/data
      - ./redis/redis.conf:/usr/local/etc/redis/redis.conf:ro
    restart: unless-stopped

  php:
    build: ./php
    volumes:
      - ./data/ips:/var/www/html
    restart: unless-stopped

  nginx:
    image: nginx:stable-alpine
    depends_on:
      - php
    ports:
      - "8080:80"
    volumes:
      - ./data/ips:/var/www/html:ro
      - ./nginx/default.conf:/etc/nginx/conf.d/default.conf:ro
      - ./data/logs/nginx:/var/log/nginx
    restart: unless-stopped
```

## 3) Create .env (DB passwords)

Create `ips-docker/.env`:

```bash
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me_root
```

Use strong passwords.

## 4) Build a PHP-FPM image (PHP 8.1 + extensions + Redis extension)

### 4.1 php/Dockerfile

Create `ips-docker/php/Dockerfile`:

```dockerfile
FROM php:8.1-fpm-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends     libicu-dev libzip-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev     libxml2-dev   && docker-php-ext-configure gd --with-freetype --with-jpeg   && docker-php-ext-install -j"$(nproc)"     intl mbstring mysqli pdo_mysql zip gd exif opcache   && pecl install redis   && docker-php-ext-enable redis   && rm -rf /var/lib/apt/lists/*

COPY php.ini /usr/local/etc/php/conf.d/99-ips.ini
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

WORKDIR /var/www/html
```

### 4.2 php/php.ini

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

### 4.3 php/www.conf (PHP-FPM performance)

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

## 5) Nginx config (IPS4 friendly URLs + static caching)

Create `ips-docker/nginx/default.conf`:

```nginx
server {
  listen 80;
  server_name _;
  root /var/www/html;
  index index.php;

  client_max_body_size 512m;

  gzip on;
  gzip_types
    text/plain text/css application/json application/javascript
    text/xml application/xml application/xml+rss text/javascript;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }

  location ~ \.php$ {
    try_files $uri =404;
    include fastcgi_params;
    fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    fastcgi_pass php:9000;
    fastcgi_read_timeout 300;
  }

  location ~* \.(?:css|js|jpg|jpeg|gif|png|webp|svg|ico|woff2?|ttf|eot)$ {
    expires 30d;
    access_log off;
    try_files $uri =404;
  }

  location ~ /\.(?!well-known) { deny all; }
}
```

## 6) MySQL 8.4 tuning

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

## 7) Redis tuning (cache + durable AOF)

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

## 8) Start the stack

From `ips-docker/`:

```bash
docker compose up -d --build
```

Open:

```text
http://SERVER-IP:8080/
```

Installer values:
- DB host: db
- DB name: ips
- DB user: ips
- DB pass: value of MYSQL_PASSWORD in .env

## 9) Enable Redis in IPS (after install)

In AdminCP, set caching to Redis:
- Host: redis
- Port: 6379

## 10) Requirements checker (optional but recommended)

Copy the IPS requirements checker into the web root, for example:

```text
./data/ips/requirements.php
```

Open:

```text
http://SERVER-IP:8080/requirements.php
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
- Redis is cache, but AOF is in ./data/redis if you want it
