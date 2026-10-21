# PHP 8.2 only. 8.1 is no longer supported; the version is intentionally not a build arg.
FROM php:8.2-fpm-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libwebp-dev \
    libxml2-dev \
    libxslt1-dev \
    libonig-dev \
    libpq-dev \
    libgmp-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j"$(nproc)" \
    intl \
    mbstring \
    mysqli \
    pdo_mysql \
    zip \
    gd \
    exif \
    opcache \
    bcmath \
    gmp \
    soap \
    xsl \
    gettext \
    calendar \
    sockets \
    shmop \
    sysvshm \
    sysvmsg \
    sysvsem \
    ftp

# Install Redis extension (phpredis) from the GitHub release tarball; pecl.php.net downloads are unreliable
ARG PHPREDIS_VERSION=6.3.0
RUN curl -fSL "https://github.com/phpredis/phpredis/archive/refs/tags/${PHPREDIS_VERSION}.tar.gz" -o /tmp/phpredis.tar.gz \
    && mkdir -p /tmp/phpredis && tar -xzf /tmp/phpredis.tar.gz -C /tmp/phpredis --strip-components=1 \
    && docker-php-ext-install -j"$(nproc)" /tmp/phpredis \
    && rm -rf /tmp/phpredis /tmp/phpredis.tar.gz

# Install ionCube Loader (required for encoded XENNTEC app releases)
RUN curl -fSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o /tmp/ioncube.tar.gz \
    && tar -xzf /tmp/ioncube.tar.gz -C /tmp \
    && cp /tmp/ioncube/ioncube_loader_lin_8.2.so "$(php -r 'echo ini_get("extension_dir");')/" \
    && echo "zend_extension=ioncube_loader_lin_8.2.so" > /usr/local/etc/php/conf.d/00-ioncube.ini \
    && rm -rf /tmp/ioncube /tmp/ioncube.tar.gz

# Create PHP session directory with proper ownership
RUN mkdir -p /var/lib/php/sessions && chown www-data:www-data /var/lib/php/sessions && chmod 1733 /var/lib/php/sessions

# Copy PHP configuration files
COPY php.ini /usr/local/etc/php/conf.d/99-ips.ini
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Install fcgi for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends libfcgi-bin \
    && rm -rf /var/lib/apt/lists/*

# Enable PHP-FPM status page for healthcheck
RUN echo 'pm.status_path = /status' >> /usr/local/etc/php-fpm.d/zz-docker.conf

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD SCRIPT_NAME=/status SCRIPT_FILENAME=/status REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000 || exit 1

COPY docker-entrypoint.sh /usr/local/bin/ips-entrypoint.sh
RUN chmod +x /usr/local/bin/ips-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/ips-entrypoint.sh"]
CMD ["php-fpm"]
