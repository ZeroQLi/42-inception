#!/bin/bash

set -e

DATA_DIR="/var/lib/mysql"
SOCKET="/run/mysqld/mysqld.sock"

load_secret() {
    local var_name="$1"
    local file_var="${var_name}_FILE"
    local value="${!var_name:-}"

    if [ -n "${!file_var:-}" ]; then
        if [ -f "${!file_var}" ]; then
            value="$(cat "${!file_var}")"
        else
            echo "Secret file ${!file_var} not found" >&2
            exit 1
        fi
    elif [ -n "$value" ] && [ -f "$value" ]; then
        value="$(cat "$value")"
    fi
    printf '%s' "$value"
}

ROOT_PASSWORD="$(load_secret MYSQL_ROOT_PASSWORD)"
APP_PASSWORD="$(load_secret MYSQL_PASSWORD)"

# Create the system tables only on the first boot.
if [ ! -d "$DATA_DIR/mysql" ]; then
    mysql_install_db --user=mysql --datadir="$DATA_DIR" > /dev/null
fi

# Start a temporary server without networking so setup stays local.
mysqld --skip-networking --socket="$SOCKET" --user=mysql &
pid="$!"

# Wait until MariaDB is ready to accept socket connections.
until mysqladmin --socket="$SOCKET" ping >/dev/null 2>&1; do
    sleep 1
done

# Set the root password, create the app database, and grant access.
mysql --socket="$SOCKET" -u root << EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${APP_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

# Stop the temporary server cleanly.
mysqladmin --socket="$SOCKET" -u root -p"${ROOT_PASSWORD}" shutdown

wait "$pid" || true

# Replace this shell with the real MariaDB server process.
exec mysqld --user=mysql --datadir="$DATA_DIR" --socket="$SOCKET"