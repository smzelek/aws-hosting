#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "kerukion-admin" > /dev/null || aws sso login --profile=kerukion-admin

aws --profile kerukion-admin ssm start-session --target $1
