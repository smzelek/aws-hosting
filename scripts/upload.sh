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

aws s3 sync terraform/haproxy/files s3://kerukion-haproxy-config/

echo
echo "Rerun haproxy setup:"
echo "bash scripts/ssh.sh haproxy"
echo "cd ~ && aws s3 sync s3://kerukion-haproxy-config/ ~"
echo "bash ~/setup.sh"
echo
