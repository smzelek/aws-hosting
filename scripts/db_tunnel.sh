#!/bin/bash
set -u
set -e
set -E
set -o pipefail

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.asg_instance_ids.value[0]')"
DB_ENDPOINT=$(terraform -chdir=terraform/ output --json | jq -r '.rds_endpoint.value')

aws ssm start-session --target "${INSTANCE_ID}" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host="${DB_ENDPOINT%:*}",portNumber="5432",localPortNumber="9999"
