#!/bin/bash
set -e

DOMAIN_NAME="${DOMAIN_NAME:?DOMAIN_NAME is required}"

if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=US/ST=State/L=City/O=Organization/CN=${DOMAIN_NAME}"
    chmod 600 /etc/nginx/ssl/nginx.key
fi

nginx -t
exec nginx -g "daemon off;"
