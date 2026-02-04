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

# Install Redis extension via PECL
RUN pecl install redis && docker-php-ext-enable redis

# Copy PHP configuration files
COPY php.ini /usr/local/etc/php/conf.d/99-ips.ini
COPY www.conf /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Create a healthcheck script
RUN echo '#!/bin/sh' > /usr/local/bin/healthcheck.sh \
    && echo 'php-fpm-healthcheck || exit 1' >> /usr/local/bin/healthcheck.sh \
    && chmod +x /usr/local/bin/healthcheck.sh

HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD /usr/local/bin/healthcheck.sh || exit 1
