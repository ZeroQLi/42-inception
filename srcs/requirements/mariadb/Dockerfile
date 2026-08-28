FROM debian:trixie

RUN apt-get update
RUN apt-get install -y mariadb-server \
    mariadb-client \
    galera-4 \
    vim && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/run/mysqld /var/log/mysql \
    && chown -R mysql:mysql /var/run/mysqld \
    && chmod u=rwx,g=rx,o=rx /var/run/mysqld

COPY ./conf/mysqld.conf /etc/mysql/mariadb.conf.d/mysqld.cnf
COPY ./tools/mariadb.sh /usr/local/bin/

RUN chmod +x /usr/local/bin/mariadb.sh

EXPOSE 3306

ENTRYPOINT [ "/usr/local/bin/mariadb.sh" ]