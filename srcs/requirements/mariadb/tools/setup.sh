#!/bin/bash
set -e

DATA_DIR="/var/lib/mysql"
ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
APP_PASSWORD="$(cat /run/secrets/db_password)"

if [ ! -d "$DATA_DIR/mysql" ]; then
    mariadb-install-db --user=mysql --datadir="$DATA_DIR" > /dev/null 2>&1

    mysqld --user=mysql --skip-networking &
    pid=$!

    until mysqladmin ping &> /dev/null; do
        sleep 1
    done

    mysql -u root << EOF
ALTER USER 'root'@'localhost'
    IDENTIFIED VIA mysql_native_password
    USING PASSWORD('${ROOT_PASSWORD}');
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${APP_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    mysqladmin -u root -p"${ROOT_PASSWORD}" shutdown
    wait "$pid" 2>/dev/null || true
else
    mysqld --user=mysql --skip-networking &
    pid=$!

    until mysqladmin ping &> /dev/null; do
        sleep 1
    done

    mysql -u root -p"${ROOT_PASSWORD}" << EOF
ALTER USER 'root'@'localhost'
    IDENTIFIED VIA mysql_native_password
    USING PASSWORD('${ROOT_PASSWORD}');
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${APP_PASSWORD}';
ALTER USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${APP_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF

    mysqladmin -u root -p"${ROOT_PASSWORD}" shutdown
    wait "$pid" 2>/dev/null || true
fi

exec mysqld --user=mysql --datadir="$DATA_DIR" --console
