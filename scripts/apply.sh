#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "${AWS_PROFILE}" > /dev/null || aws sso login --profile "${AWS_PROFILE}"

rm -f terraform/generated_resources.tf
terraform -chdir=terraform init
terraform -chdir=terraform apply || terraform -chdir=terraform/ output
aws s3 sync --profile "${AWS_PROFILE}" terraform/haproxy/files s3://kerukion-haproxy-config/

echo "bash scripts/ssh.sh \"$(terraform -chdir=terraform/ output --json | jq -r '.haproxy_instance_id.value[0]')\""
echo "sudo aws s3 cp s3://kerukion-haproxy-config/setup.sh ~"
echo "bash ~/setup.sh"
