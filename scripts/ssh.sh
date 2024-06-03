#!/bin/bash
set -e
set -E
set -o pipefail

# source in env vars
. .env
TARGET="${1}"

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

if [[ "${TARGET}" == "haproxy" ]]; then
    INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.haproxy_instance_id.value[0]')"
elif [[ "${TARGET}" == "cluster" ]]; then
    INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.asg_instance_id.value[0]')"
else
    INSTANCE_ID="${TARGET}"
fi

aws ssm start-session --target "${INSTANCE_ID}"
