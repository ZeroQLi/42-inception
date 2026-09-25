*This project has been created as part of the 42 curriculum by mtangalv.*

# Inception

A 42 Abu Dhabi Project that teaches you the basics of containerization, Docker and using services.

## Description

Inception is a small containerized infrastructure project using. With the main goal being to build a wordpress site behind a reverse proxy, using mariaDB for data persistence.

The project stack is composed of three services:

- **NGINX**: the public HTTPS entry point on port 443. Forwarding PHP requests to WordPress via HTTP.
- **WordPress**: a PHP-FPM application container that installs and serves the WordPress site.
- **MariaDB**: the database server used by WordPress.

Each service has its own Dockerfile, configuration, and startup script, communicate through a private Docker bridge network and store their data in persistent Docker volumes.

## Project Description

### Docker design

Docker packages each service with its runtime dependencies and isolates it from the host and from unrelated services. Docker Compose defines the complete multi-container application: images, containers, enviroment variables, secrets, network and other important parts of the setup.

The repository contains:

- `Makefile`: convenience commands for creating data directories, building, starting, stopping, and cleaning the stack.
- `srcs/docker-compose.yml`: the service, network, volume, and secret definitions.
- `srcs/requirements/mariadb`: the MariaDB Dockerfile, configuration, and initialization script.
- `srcs/requirements/wordpress`: the PHP-FPM/WordPress Dockerfile, pool configuration, and setup script.
- `srcs/requirements/nginx`: the NGINX Dockerfile, HTTPS configuration, and certificate-generation script.
- `srcs/.env`: local non-secret deployment configuration. To be added locally.
- `secrets/`: local Docker secret files. To be added locally.

### Virtual machines versus Docker

| Virtual machines | Docker containers |
| --- | --- |
| Emulate or virtualize a complete operating system. | Share the host kernel while isolating processes and filesystems. |
| Usually require more memory and disk space. | Usually start faster and use fewer resources. |
| Provide stronger operating-system isolation. | Provide lightweight, reproducible service packaging. |
| A full VM is useful when a different kernel or operating system is required. | Containers are useful when applications need isolated, repeatable environments. |

This project uses Docker because the three services need separate runtimes but do not need separate virtual machines.

### Secrets versus environment variables

Environment variables are convenient for non-sensitive configuration such as database names, usernames, domain names and api keys. They can be visible through container metadata and process environments, but are still to be treated with caution.

Docker secrets mount sensitive values as files under `/run/secrets`. This project uses secrets for the MariaDB root password and application database password. Real secret files remain local and untracked.

### Docker network versus host network

A Docker bridge network gives containers private name-based communication. For example, WordPress can reach MariaDB using the service name `mariadb`, and NGINX can reach PHP-FPM using `wordpress:9000`.

Host networking would place a container directly on the host network namespace. That would reduce isolation and could cause port conflicts. This project intentionally uses a custom bridge network and publishes only NGINX port 443.

### Docker volumes versus bind mounts

A Docker-managed volume is managed by Docker and is portable within Docker's storage system. A bind mount maps a specific host path into a container and makes the location explicit for backup and access.

This project defines named Docker volumes with the local volume options:

```
/home/<host-user>/data/mariadb
/home/<host-user>/data/wordpress
```

## Instructions

### Prerequisites

Install the following on the host machine:

- Docker Engine
- Docker Compose v2 through the Docker Compose plugin
- Permission to run Docker commands
- A DNS or `/etc/hosts` entry mapping to the Docker host

For a local Docker host, an `/etc/hosts` entry can be:

```text
127.0.0.1 username.42.fr
```

When Docker runs inside a VM, use the VM's reachable IP address instead.

### Local configuration

The Compose file requires `srcs/.env` and these secret files:

```text
secrets/db_root_password.txt
secrets/db_app_password.txt
```

Keep the real files untracked. The `.env` file must define the deployment values used by Compose, including the domain, database names and users, WordPress title, and WordPress user details. Each secret file should contain one password followed by a newline.

Protect the files on the host:

```sh
chmod 600 srcs/.env secrets/db_root_password.txt secrets/db_app_password.txt
```

Do not commit real passwords or add them to documentation.

### Build and start

Run commands from the repository root:

```sh
make all
```

This creates the host data directories, builds the three images, and starts the stack in detached mode.

The equivalent Compose command after the data directories exist is:

```sh
$ docker compose -f srcs/docker-compose.yml up -d --build
```

Open the website at:

```text
https://user.42.fr
```
where user is the hostname added to your ``/etc/hosts`` file

The certificate is self-signed, so a browser warning is expected unless the certificate has been trusted locally.

### Stop and clean

Stop and remove containers while preserving data:

```sh
make clean
```

Start the existing installation again:

```sh
make up
```

Remove containers, Docker volumes, images, and the host data directories:

```sh
make fclean
```

`make fclean` is destructive. It removes the WordPress site, MariaDB database, and all persistent project data.

## Documentation

- [`USER_DOC.md`](USER_DOC.md): operating the stack, accessing WordPress, managing credentials.
- [`DEV_DOC.md`](DEV_DOC.md): setting up a development machine, building the stack, managing Compose resources, and understanding persistence.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose documentation](https://docs.docker.com/compose/)
- [Dockerfile reference](https://docs.docker.com/reference/dockerfile/)
- [Docker volumes](https://docs.docker.com/engine/storage/volumes/)
- [Docker networking](https://docs.docker.com/engine/network/)
- [Docker secrets](https://docs.docker.com/engine/swarm/secrets/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)
- [MariaDB documentation](https://mariadb.com/docs/)
- [WP-CLI documentation](https://wp-cli.org/)
- [WordPress documentation](https://wordpress.org/documentation/)

### AI usage

AI assistance was used for the following tasks:

- Explaining Docker process ownership, MariaDB entrypoint behavior, and persistence testing.
- Drafting and reviewing this documentation.
- Testing an verifying errors or setbacks on new VMS
