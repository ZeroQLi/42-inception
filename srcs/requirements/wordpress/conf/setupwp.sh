#!/bin/bash
set -e

WP_PATH="/var/www/html"

if [ -n "${WORDPRESS_DB_PASSWORD_FILE:-}" ] && [ -f "$WORDPRESS_DB_PASSWORD_FILE" ]; then
    export WORDPRESS_DB_PASSWORD="$(cat "$WORDPRESS_DB_PASSWORD_FILE")"
fi

if [ ! -f "$WP_PATH/wp-config.php" ]; then
    wget -q https://wordpress.org/latest.zip -O /tmp/wordpress.zip
    unzip -q /tmp/wordpress.zip -d /tmp
    cp -rn /tmp/wordpress/. "$WP_PATH/"
    rm -rf /tmp/wordpress /tmp/wordpress.zip

    cat > "$WP_PATH/wp-config.php" << EOF
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

    chown -R www-data:www-data "$WP_PATH"
fi

exec php-fpm8.4 -F