#!/bin/bash
set -e

# source in env vars
. .env

# verify identity
aws sts get-caller-identity --query "Account" --profile "kerukion-admin" > /dev/null || aws sso login --profile=kerukion-admin

aws --profile kerukion-admin ssm start-session --target $1 \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters host="cluster-db.cz6coaa0okhg.us-east-1.rds.amazonaws.com",portNumber="5432",localPortNumber="9999"
