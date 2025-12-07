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
    TF_OUTPUT="$(terraform -chdir=terraform/ output --json)"
    INSTANCE_ID="$(echo $TF_OUTPUT | jq -r '.haproxy_instance_id.value')"
elif [[ "${TARGET}" == "cluster" ]]; then
    TF_OUTPUT="$(terraform -chdir=terraform/ output --json)"
    INSTANCE_ID="$(echo $TF_OUTPUT | jq -r '.asg_instance_ids.value')"
else
    INSTANCE_ID="${TARGET}"
fi

aws ssm start-session --target "${INSTANCE_ID}"
