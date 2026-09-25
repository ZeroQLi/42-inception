FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    unzip \
    mariadb-client \
    curl && rm -rf /var/lib/apt/lists/*

WORKDIR /var/www/html

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/setupwp.sh /usr/local/bin/

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp /usr/local/bin/setupwp.sh

EXPOSE 9000

ENTRYPOINT ["bash", "/usr/local/bin/setupwp.sh"]