FROM debian:bookworm

RUN apt-get update && apt-get install -y \
	mariadb-server \
	mariadb-client \
	curl \
	&& rm -rf /var/lib/apt/lists/*

COPY ./conf/mysqld.cnf /etc/mysql/mariadb.conf.d/50-server.cnf
COPY ./tools/setup.sh /usr/local/bin/setup.sh

RUN mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld /var/log/mysql \
    && chmod u=rwx,g=rx,o=rx /var/run/mysqld

RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 3306

ENTRYPOINT ["bash", "/usr/local/bin/setup.sh"]