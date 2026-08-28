FROM debian:trixie

RUN apt-get update && apt-get install -y \
    php8.4-fpm \
    php8.4-mysql \
    php8.4-curl \
    php8.4-gd \
    php8.4-intl \
    php8.4-mbstring \
    php8.4-soap \
    php8.4-xml \
    php8.4-zip \
    wget \
    curl \
    unzip && rm -rf /var/lib/apt/lists/*

# Create WordPress directory
WORKDIR /var/www/html

# Copy PHP-FPM configuration (correct version)
COPY conf/www.conf /etc/php/8.4/fpm/pool.d/

# Copy and set permissions for setup script
COPY conf/setupwp.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setupwp.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setupwp.sh"]