#!/bin/bash
set -e

# source in env vars
. .env
INSTANCE_ID="${1}"

# verify identity
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

aws --profile "${AWS_PROFILE}" ssm start-session --target "${INSTANCE_ID}"
