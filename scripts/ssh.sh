#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/.."

set -u
set -e
set -E
set -o pipefail

# source in env vars
. .env
TARGET="${1}" # aws instance ID, aka `i-11010101010101`

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

if [[ "${TARGET}" == "haproxy" ]]; then
    INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.haproxy_instance_id.value[0]')"
elif [[ "${TARGET}" == "cluster" ]]; then
    INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.asg_instance_ids.value[0]')"
else
    INSTANCE_ID="${TARGET}"
fi

aws ssm start-session --target "${INSTANCE_ID}"
