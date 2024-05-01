#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity || aws sso login --profile=kerukion-admin
terraform -chdir=terraform init
rm -f terraform/generated_resources.tf
terraform -chdir=terraform plan -generate-config-out=generated_resources.tf

