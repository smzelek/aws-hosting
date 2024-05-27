#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "kerukion-admin" > /dev/null || aws sso login --profile=kerukion-admin

terraform -chdir=terraform init
terraform -chdir=terraform apply || terraform -chdir=terraform/ output
