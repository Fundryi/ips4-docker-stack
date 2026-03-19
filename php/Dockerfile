FROM php:8.1-fpm-bookworm

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

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Install ionCube Loader (required for encoded XENNTEC app releases)
RUN curl -fSL https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz -o /tmp/ioncube.tar.gz \
    && tar -xzf /tmp/ioncube.tar.gz -C /tmp \
    && cp /tmp/ioncube/ioncube_loader_lin_8.1.so "$(php -r 'echo ini_get("extension_dir");')/" \
    && echo "zend_extension=ioncube_loader_lin_8.1.so" > /usr/local/etc/php/conf.d/00-ioncube.ini \
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
