# User Documentation

This document explains how to use the running Inception stack as an administrator or end user.

## Services Provided

The project provides a WordPress website through three containers:

- **NGINX** provides the public HTTPS endpoint on port 443.
- **WordPress with PHP-FPM** runs the website application.
- **MariaDB** stores the WordPress database.

Only NGINX is intended to be accessed directly from the host. MariaDB and PHP-FPM communicate internally through the Docker network.

## Starting the Project

Run this command from the repository root:

```sh
make up
```

On a new installation, use this first because it creates the data directories and builds the images:

```sh
make all
```

The website is available at:

```text
https://mtangalv.42.fr
```

If the browser reports that the certificate is not trusted, this is expected because the project generates a self-signed certificate.

## Stopping the Project

Stop the containers while preserving the website and database:

```sh
make clean
```

Start them again later with:

```sh
make up
```

Do not use `make fclean` for a normal shutdown. It removes the containers, images, Docker volumes, and persistent host data.

## Website and Administration Panel

Open the main website at:

```text
https://mtangalv.42.fr
```

Open the WordPress administration panel at:

```text
https://mtangalv.42.fr/wp-admin/
```

Use the administrator username and password configured during the initial WordPress installation. The administrator username is configured through `WP_ADMIN_USER` in the local `srcs/.env` file.

The second configured WordPress account is intended as a non-administrator user. It can be used to test normal website actions such as posting comments, depending on the WordPress page and comment settings.

## Credentials

Credentials are stored on the Docker host, not in this documentation:

```text
srcs/.env
secrets/db_root_password.txt
secrets/db_app_password.txt
```

The `.env` file contains WordPress and database configuration values, including the initial WordPress account passwords. The secret files contain the MariaDB root and application database passwords.

Protect these files:

```sh
chmod 600 srcs/.env secrets/db_root_password.txt secrets/db_app_password.txt
```

Never publish or commit real passwords. If a password is exposed, rotate it and update every service that uses it. Password changes on an existing installation may require updating both the MariaDB account and the persistent WordPress `wp-config.php` file.

Changing `WP_ADMIN_PASSWORD` in `.env` does not automatically change an administrator account that already exists. Existing WordPress users must be updated through the WordPress administration panel or WP-CLI.

## Checking Service Health

Check the Compose service state:

```sh
$ docker compose -f srcs/docker-compose.yml ps
```

The `mariadb`, `wordpress`, and `nginx` services should be running.

Check recent logs:

```sh
$ docker compose -f srcs/docker-compose.yml logs --tail=100 mariadb
$ docker compose -f srcs/docker-compose.yml logs --tail=100 wordpress
$ docker compose -f srcs/docker-compose.yml logs --tail=100 nginx
```

Test the HTTPS endpoint from the Docker host:

```sh
curl -kI https://mtangalv.42.fr
```

The `-k` option allows testing with the self-signed certificate. A successful response should include an HTTP status such as `200`, `301`, or `302`.

The project does not publish port 80. A request to the HTTP URL should not reach the NGINX container:

```sh
curl -I http://mtangalv.42.fr
```

Inspect persistent volumes:

```sh
$ docker volume ls
$ docker volume inspect srcs_mariadb_data
$ docker volume inspect srcs_wordpress_data
```

The volume configuration should point to host directories similar to:

```text
/home/<host-user>/data/mariadb
/home/<host-user>/data/wordpress
```

## Data Persistence

WordPress files are stored in the WordPress data directory, and MariaDB stores its database files in the MariaDB data directory. Running `make clean` or rebooting the host should not remove this data.

To verify persistence:

1. Create or edit a WordPress page.
2. Stop the stack with `make clean` or reboot the host.
3. Start it again with `make up`.
4. Confirm that the page, users, comments, and database data remain available.

Do not run `make fclean` during this test because it intentionally deletes persistent data.

## Basic Recovery Information

If the website is unavailable:

1. Check `docker compose ps`.
2. Check the MariaDB, WordPress, and NGINX logs.
3. Confirm that `srcs/.env` and both secret files exist.
4. Confirm that the host data directories exist and are readable by Docker.
5. Confirm that the domain resolves to the Docker host.
6. Restart the containers with `make up`.

Do not delete volumes as a first troubleshooting step. Deleting the volumes removes the database and WordPress installation.
