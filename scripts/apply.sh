#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "${SCRIPT_DIR}/.."

set -u
set -e
set -E
set -o pipefail

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

rm -f terraform/generated_resources.tf
terraform -chdir=terraform init
terraform -chdir=terraform apply || terraform -chdir=terraform/ output
bash ./scripts/upload.sh

