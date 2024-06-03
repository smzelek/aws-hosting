#!/bin/bash
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
aws s3 sync terraform/haproxy/files s3://kerukion-haproxy-config/

echo "bash scripts/ssh.sh haproxy"
echo "aws s3 sync s3://kerukion-haproxy-config/ ~ && bash ~/setup.sh"
