#!/usr/bin/env bash
# Generate CodeArtifact token and url
# Inputs (env): ACCOUNT, DOMAIN, REGION, REPOSITORY
# Outputs: TOKEN, HOST, REPO_ID. Env: ARTIFACT_STORE_HOST
set -eo pipefail

TOKEN=$(aws codeartifact get-authorization-token --domain "$DOMAIN" --domain-owner "$ACCOUNT" --query authorizationToken --output text)
echo "::add-mask::$TOKEN"
HOST="$DOMAIN-$ACCOUNT.d.codeartifact.$REGION.amazonaws.com"
REPO_ID="$DOMAIN-$REPOSITORY"
{
  echo "TOKEN=$TOKEN"
  echo "HOST=$HOST"
  echo "REPO_ID=$REPO_ID"
} >> "$GITHUB_OUTPUT"
echo "ARTIFACT_STORE_HOST=$HOST" >> "$GITHUB_ENV"
