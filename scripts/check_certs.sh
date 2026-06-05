#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/.."

set -u
set -o pipefail

WARN_DAYS=30
NOW=$(date +%s)

DOMAINS=(
    learnderby.com
    api.learnderby.com
    ticmetactoe.com
    api.ticmetactoe.com
    stevezelek.com
    wow.stevezelek.com
    pokegrader.com
    takemeapart.com
    canyoulearnmusic.com
)

for domain in "${DOMAINS[@]}"; do
    expiry_str=$(echo \
        | openssl s_client -servername "${domain}" -connect "${domain}:443" 2>/dev/null \
        | openssl x509 -noout -enddate 2>/dev/null \
        | cut -d= -f2)

    if [ -z "${expiry_str}" ]; then
        printf "%-35s  %-25s  %s\n" "${domain}" "unreachable" "[ERROR]"
        continue
    fi

    expiry_epoch=$(date -j -f "%b %d %T %Y %Z" "${expiry_str}" +%s 2>/dev/null \
        || date -d "${expiry_str}" +%s)
    days_left=$(( (expiry_epoch - NOW) / 86400 ))

    if [ "${days_left}" -lt 0 ]; then
        status="EXPIRED"
    elif [ "${days_left}" -lt "${WARN_DAYS}" ]; then
        status="EXPIRING SOON"
    else
        status="OK"
    fi

    printf "%-35s  expires %-25s  %3d days  [%s]\n" \
        "${domain}" "${expiry_str}" "${days_left}" "${status}"
done
