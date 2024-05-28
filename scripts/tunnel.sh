#!/bin/bash
set -e

# source in env vars
. .env

INSTANCE_ID="$(terraform -chdir=terraform/ output --json | jq -r '.asg_instance_ids.value[0]')"
DB_ENDPOINT=$(terraform -chdir=terraform/ output --json | jq -r '.rds_endpoint.value')

# verify identity
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

aws --profile "${AWS_PROFILE}" ssm start-session --target "${INSTANCE_ID}" \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host="${DB_ENDPOINT}",portNumber="5432",localPortNumber="9999"
