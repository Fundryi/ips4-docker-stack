FROM php:8.1-fpm-bookworm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libicu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libxml2-dev \
    libonig-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" \
    intl \
    mbstring \
    mysqli \
    pdo_mysql \
    zip \
    gd \
    exif \
    opcache \
    bcmath

# Install GMP extension (for Web Push Notifications)
RUN apt-get update && apt-get install -y libgmp-dev \
    && docker-php-ext-install gmp

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

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
