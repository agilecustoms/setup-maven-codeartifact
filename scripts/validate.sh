#!/usr/bin/env bash
# Validate inputs
# Inputs (env): REPOSITORY, JAVA_CACHE
set -eo pipefail

if [[ -z "$REPOSITORY" ]]; then
  echo "Input 'aws-codeartifact-repository' must not be empty"
  exit 1
fi
if [[ "$JAVA_CACHE" != "maven" && "$JAVA_CACHE" != "" ]]; then
  echo "Error: input 'java-cache' must be either 'maven' or an empty string." >&2
  exit 1
fi
