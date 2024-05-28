#!/bin/bash
set -e
set -E
set -o pipefail

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

terraform -chdir=terraform init
rm -f terraform/generated_resources.tf
terraform -chdir=terraform plan -generate-config-out=generated_resources.tf

