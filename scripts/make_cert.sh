#!/bin/bash
set -e
set -E
set -o pipefail

. .env
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

DOMAIN="${1}"
certbot certonly \
    -d "*.${DOMAIN}","${DOMAIN}" \
    -m smzelek@gmail.com \
    --manual \
    --agree-tos \
    --preferred-challenges dns \
    --logs-dir ./certs/logs/ \
    --config-dir ./certs/config/ \
    --work-dir ./certs/work/

cat \
"./certs/config/live/${DOMAIN}/fullchain.pem" \
"./certs/config/live/${DOMAIN}/privkey.pem" \
> ./terraform/haproxy/files/${DOMAIN}.pem
