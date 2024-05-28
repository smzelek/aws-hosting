#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

terraform -chdir=terraform/ output
