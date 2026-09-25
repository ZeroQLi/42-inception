#!/bin/bash
set -e

WP_PATH="/var/www/html"
WP_URL="https://${DOMAIN_NAME}"

export WORDPRESS_DB_PASSWORD="$(cat /run/secrets/db_password)"

if [ ! -f "$WP_PATH/wp-includes/version.php" ]; then
    mkdir -p "$WP_PATH"
    curl -fsSL https://wordpress.org/latest.zip -o /tmp/wordpress.zip
    unzip -q /tmp/wordpress.zip -d /tmp
    cp -r /tmp/wordpress/. "$WP_PATH/"
    rm -rf /tmp/wordpress /tmp/wordpress.zip
    chown -R www-data:www-data "$WP_PATH"
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    cat > "$WP_PATH/wp-config.php" <<EOF
<?php
define('DB_NAME', '${WORDPRESS_DB_NAME}');
define('DB_USER', '${WORDPRESS_DB_USER}');
define('DB_PASSWORD', '${WORDPRESS_DB_PASSWORD}');
define('DB_HOST', '${WORDPRESS_DB_HOST}');
\$table_prefix = '${WORDPRESS_TABLE_PREFIX:-wp_}';
define('WP_DEBUG', false);
if ( !defined('ABSPATH') )
    define('ABSPATH', __DIR__ . '/');
require_once ABSPATH . 'wp-settings.php';
EOF
fi

echo "Waiting for MariaDB..."

attempt=1
max_attempts=30

until mysqladmin ping \
    -h "$WORDPRESS_DB_HOST" \
    -u "$WORDPRESS_DB_USER" \
    -p"$WORDPRESS_DB_PASSWORD" \
    --silent >/dev/null 2>&1
do
    if [ "$attempt" -ge "$max_attempts" ]; then
        echo "MariaDB did not become ready in time"
        exit 1
    fi

    sleep 2
    attempt=$((attempt + 1))
done

echo "MariaDB is ready"

if ! wp core is-installed --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    wp core install \
        --path="$WP_PATH" \
        --url="$WP_URL" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root
fi

if ! wp user get "${WP_USER2}" --path="$WP_PATH" --allow-root >/dev/null 2>&1; then
    wp user create "${WP_USER2}" "${WP_USER2_EMAIL}" \
        --user_pass="${WP_USER2_PASSWORD}" \
        --role=subscriber \
        --path="$WP_PATH" \
        --allow-root
fi

chown -R www-data:www-data "$WP_PATH"
exec php-fpm8.2 -F
