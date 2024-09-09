#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -u
set -e
set -E
set -o pipefail

# source in env vars
. "${SCRIPT_DIR}/../.env"

# verify identity
aws sts get-caller-identity --query "Account" > /dev/null || aws sso login

ROLE_CREDS=$(aws sts assume-role --role-arn "arn:aws:iam::590184101838:role/wow-stevezelek-com-github-role" --role-session-name "test1")

export AWS_ACCESS_KEY_ID=$(echo $ROLE_CREDS | jq -r '.Credentials.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_CREDS | jq -r '.Credentials.SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo $ROLE_CREDS | jq -r '.Credentials.SessionToken')

# aws s3 cp --recursive clickable_prescience_frames/src/ s3://stevezelek-com/files/clickable_prescience_frames/src/
# aws s3 cp clickable_prescience_frames/version s3://stevezelek-com/files/clickable_prescience_frames/version
# aws s3 cp clickable_prescience_frames/WAGO_README.md s3://stevezelek-com/files/clickable_prescience_frames/WAGO_README.md
# aws s3 cp clickable_prescience_frames/wago.lua s3://stevezelek-com/files/clickable_prescience_frames/wago.lua
