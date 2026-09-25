# Developer Documentation

This document explains how to set up, build, operate, inspect, and reset the Inception development environment.

## Prerequisites

The development machine needs:

- Docker Engine
- Docker Compose v2 and the `docker compose` command
- GNU Make
- A user account allowed to run Docker commands
- A hostname or `/etc/hosts` entry for `mtangalv.42.fr`

Check the installation with:

```sh
$ docker --version
$ docker compose version
$ make --version
```

Run all commands below from the repository root.

## Repository Layout

```text
.
├── Makefile
├── README.md
├── DEV_DOC.md
├── USER_DOC.md
├── secrets/
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        ├── nginx/
        └── wordpress/
```

Real `.env` and secret files are local deployment inputs and must remain untracked. The repository should contain safe examples or setup instructions, not active credentials.

## Configuration From Scratch

### Environment file

Create `srcs/.env` with the values required by `srcs/docker-compose.yml`:

- `LOGIN`
- `DOMAIN_NAME`
- `MYSQL_DATABASE`
- `MYSQL_USER`
- `WORDPRESS_DB_NAME`
- `WORDPRESS_DB_USER`
- `WORDPRESS_TABLE_PREFIX`
- `WP_TITLE`
- `WP_ADMIN_USER`
- `WP_ADMIN_PASSWORD`
- `WP_ADMIN_EMAIL`
- `WP_USER2`
- `WP_USER2_EMAIL`
- `WP_USER2_PASSWORD`

The configured administrator username must not contain `admin` or `Admin`, as required by the Inception project. The current domain is `mtangalv.42.fr`.

The Compose and Makefile volume paths use the host shell's `$USER` value, not the `LOGIN` variable. Run the project as the intended host user so the paths resolve to the expected location.

### Docker secret files

Create these files:

```text
secrets/db_root_password.txt
secrets/db_app_password.txt
```

Each file should contain only its corresponding password. Protect them with:

```sh
chmod 600 srcs/.env secrets/db_root_password.txt secrets/db_app_password.txt
```

The Compose file mounts the secrets into the containers as:

```text
/run/secrets/db_root_password
/run/secrets/db_password
```

Do not put real passwords in Git, Dockerfiles, README files, or shell command history.

## Build and Launch

The normal first-run command is:

```sh
make all
```

The `all` target runs `build` and then `up`. The build target creates the host data directories and builds the three custom images:

```sh
make build
make up
```

The direct Compose equivalent is:

```sh
$ docker compose -f srcs/docker-compose.yml up -d --build
```

Validate Compose interpolation without starting containers:

```sh
$ docker compose -f srcs/docker-compose.yml config --quiet
```

The shell scripts can be syntax-checked with:

```sh
bash -n srcs/requirements/mariadb/tools/setup.sh
bash -n srcs/requirements/wordpress/tools/setupwp.sh
bash -n srcs/requirements/nginx/tools/generate_ssl.sh
```

## Makefile Commands

| Command | Effect | Data preserved? |
| --- | --- | --- |
| `make all` | Create data directories, build images, and start services. | Yes |
| `make build` | Create data directories and build images. | Yes |
| `make up` | Start the existing Compose stack in detached mode. | Yes |
| `make clean` | Stop and remove containers. | Yes |
| `make fclean` | Remove containers, volumes, images, and host data directories. | No |
| `make re` | Run `fclean`, then rebuild and start the stack. | No |

Use `make clean`, not `make fclean`, when stopping the project without deleting its data.

## Compose Operations

View service state:

```sh
$ docker compose -f srcs/docker-compose.yml ps
```

Follow logs for all services:

```sh
$ docker compose -f srcs/docker-compose.yml logs -f
```

Follow one service:

```sh
$ docker compose -f srcs/docker-compose.yml logs -f mariadb
$ docker compose -f srcs/docker-compose.yml logs -f wordpress
$ docker compose -f srcs/docker-compose.yml logs -f nginx
```

Open a shell in a running container when diagnosing it:

```sh
$ docker compose -f srcs/docker-compose.yml exec mariadb bash
$ docker compose -f srcs/docker-compose.yml exec wordpress bash
$ docker compose -f srcs/docker-compose.yml exec nginx bash
```

Inspect the container process tree:

```sh
$ docker compose -f srcs/docker-compose.yml exec mariadb ps -o pid,ppid,args
```

The final MariaDB process should be PID 1 after startup. The same principle applies to PHP-FPM and NGINX: the long-running service must remain in the foreground.

## Volumes and Persistence

The Compose file declares two named volumes backed by host directories:

```text
/home/<host-user>/data/mariadb
/home/<host-user>/data/wordpress
```

Inspect the volumes:

```sh
$ docker volume ls
$ docker volume inspect srcs_mariadb_data
$ docker volume inspect srcs_wordpress_data
```

The exact volume names can vary with the Compose project name. Use `docker volume ls` if the expected prefix is different.

To test persistence without deleting data:

1. Create or edit a WordPress page.
2. Create a test database row or verify the WordPress tables.
3. Run `make clean`, or reboot the host for a full persistence test.
4. Run `make up` after the restart.
5. Confirm the WordPress content and database data still exist.

Never use `make fclean` during a persistence test.

## Credentials and Rotation

The MariaDB application password is stored in `secrets/db_app_password.txt` and is mounted into both MariaDB and WordPress. WordPress writes its database credentials to the persistent `wp-config.php` file on initial setup.

Changing the database secret while persistent volumes exist requires care:

- MariaDB updates the database account during its startup initialization.
- Existing WordPress `wp-config.php` may still contain the old password.
- WordPress administrator passwords are only used during initial installation.

Do not rotate credentials casually on an existing installation. Back up the database and WordPress data, update both MariaDB and WordPress configuration consistently, and verify the site before removing the old credentials.

## Networking

The services share the Compose bridge network declared as `inception-network`. The resolved Docker network is normally named similar to `srcs_inception-network`.

Expected service connections are:

```text
nginx -> wordpress:9000
wordpress -> mariadb:3306
```

Only NGINX publishes a host port:

```text
host:443 -> nginx:443
```

MariaDB and PHP-FPM are internal services and should not have host port mappings.

## Troubleshooting Checklist

Check the following before changing persistent data:

```sh
$ docker compose -f srcs/docker-compose.yml ps
$ docker compose -f srcs/docker-compose.yml logs mariadb
$ docker compose -f srcs/docker-compose.yml logs wordpress
$ docker compose -f srcs/docker-compose.yml logs nginx
$ docker volume ls
```

Common causes of startup failure include missing secret files, missing `.env` values, an incorrect host `$USER`, missing `/home/<user>/data` directories, or a MariaDB initialization error.

To inspect the rendered Compose configuration without starting it:

```sh
$ docker compose -f srcs/docker-compose.yml config
```

Do not use `docker compose down -v`, `docker volume prune`, or `make fclean` unless deleting all project data is intentional.
