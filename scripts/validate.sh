#!/usr/bin/env bash
# Validate inputs
# Inputs (env): ACCOUNT, DOMAIN, REGION, REPOSITORY, JAVA_CACHE
set -eo pipefail

# GitHub does not enforce 'required: true' on action inputs, so empty (or not passed) value must be checked explicitly
missing=()
[[ -n "$ACCOUNT" ]] || missing+=("aws-account")
[[ -n "$DOMAIN" ]] || missing+=("aws-codeartifact-domain")
[[ -n "$REGION" ]] || missing+=("aws-region")
[[ -n "$REPOSITORY" ]] || missing+=("aws-codeartifact-repository")
if (( ${#missing[@]} > 0 )); then
  echo "Error: required input(s) must not be empty: ${missing[*]}" >&2
  exit 1
fi
if [[ "$JAVA_CACHE" != "maven" && "$JAVA_CACHE" != "" ]]; then
  echo "Error: input 'java-cache' must be either 'maven' or an empty string." >&2
  exit 1
fi
