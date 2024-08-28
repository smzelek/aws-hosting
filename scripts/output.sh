#!/bin/bash
set -u
set -e
set -E
set -o pipefail

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

terraform -chdir=terraform/ apply -refresh-only
terraform -chdir=terraform/ output
