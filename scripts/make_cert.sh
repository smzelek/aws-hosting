#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/.."

set -u
set -e
set -E
set -o pipefail

DOMAIN="${1}"

rm -rf "certs/config/archive/${DOMAIN}"
rm -rf "certs/config/live/${DOMAIN}"
rm -rf "certs/config/renewal/${DOMAIN}.conf"
rm -rf "terraform/haproxy/files/${DOMAIN}.pem"

# ex:
# dig txt _acme-challenge.guildvaults.com @8.8.8.8
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

openssl x509 -subject -issuer -noout -startdate -enddate -in ./terraform/haproxy/files/${DOMAIN}.pem
