#!/usr/bin/env bash
# Validates the HCP Terraform org/workspace/token and makes them available to
# terraform (TF_CLOUD_ORGANIZATION, TF_WORKSPACE, TF_TOKEN_<host>) for the backend.
#
# Usage:
#   source scripts/setup.sh   # exports the vars into your current shell
#   ./scripts/setup.sh        # validates only; a child process can't export to your shell
# In GitHub Actions the vars are also appended to $GITHUB_ENV for later steps.
#
# Required env vars:
#   TF_CLOUD_ORGANIZATION        HCP Terraform organization name
#   TF_WORKSPACE                 HCP Terraform workspace name
#   TF_TOKEN_app_terraform_io    HCP Terraform API token
#                                (falls back to `terraform login` credentials file)

# When sourced, don't change the caller's shell options or kill it with `exit`
(return 0 2> /dev/null) && SOURCED=1 || SOURCED=0
if [[ "$SOURCED" -eq 0 ]]; then
  set -euo pipefail
fi

fail() {
  printf "\033[0;31m%s\033[0m\n" "$1" >&2
  if [[ "$SOURCED" -eq 1 ]]; then return 1; else exit 1; fi
}

# Check for required tools
for tool in terraform sed curl jq; do
  command -v "$tool" > /dev/null || fail "'${tool}' is not installed; please install it and run this script again." || return 1
done

# Check the minimum required Terraform version
minimumTerraformMajorVersion=0
minimumTerraformMinorVersion=14
minimumTerraformVersion=$((minimumTerraformMajorVersion * 1000 + minimumTerraformMinorVersion))

TERRAFORM_VERSION=$(terraform version -json | jq -r '.terraform_version')
installedTerraformMajorVersion=$(cut -d '.' -f 1 <<< "$TERRAFORM_VERSION")
installedTerraformMinorVersion=$(cut -d '.' -f 2 <<< "$TERRAFORM_VERSION")
installedTerraformVersion=$((installedTerraformMajorVersion * 1000 + installedTerraformMinorVersion))

if [ "$installedTerraformVersion" -lt "$minimumTerraformVersion" ]; then
  fail "Terraform $minimumTerraformMajorVersion.$minimumTerraformMinorVersion.x or later is required (found $TERRAFORM_VERSION)." || return 1
fi

HOST="${1:-app.terraform.io}"

# Token: env var first, then the static credentials file from `terraform login`
CREDENTIALS_FILE="$HOME/.terraform.d/credentials.tfrc.json"
if [[ "$OSTYPE" =~ ^msys || "$OSTYPE" =~ ^cygwin || "$OSTYPE" =~ ^win32 ]]; then
  CREDENTIALS_FILE="$APPDATA/terraform.d/credentials.tfrc.json"
fi

TOKEN_VAR="TF_TOKEN_${HOST//./_}"
TOKEN="${!TOKEN_VAR:-}"
if [[ -z "$TOKEN" && -f "$CREDENTIALS_FILE" ]]; then
  TOKEN=$(jq -r --arg h "$HOST" '.credentials[$h].token // empty' "$CREDENTIALS_FILE")
fi

# Report everything that is missing in one go
missing=()
[[ -n "${TF_CLOUD_ORGANIZATION:-}" ]] || missing+=("TF_CLOUD_ORGANIZATION")
[[ -n "${TF_WORKSPACE:-}" ]] || missing+=("TF_WORKSPACE")
[[ -n "$TOKEN" ]] || missing+=("$TOKEN_VAR (or run 'terraform login')")
if ((${#missing[@]})); then
  fail "Missing required: ${missing[*]}" || return 1
fi

export TF_CLOUD_ORGANIZATION TF_WORKSPACE
export "$TOKEN_VAR=$TOKEN"

# Make them available to later GitHub Actions steps too
if [[ -n "${GITHUB_ENV:-}" ]]; then
  {
    echo "TF_CLOUD_ORGANIZATION=$TF_CLOUD_ORGANIZATION"
    echo "TF_WORKSPACE=$TF_WORKSPACE"
  } >> "$GITHUB_ENV"
  echo "::add-mask::$TOKEN"
  echo "$TOKEN_VAR=$TOKEN" >> "$GITHUB_ENV"
fi

echo "HCP Terraform settings ready: organization=$TF_CLOUD_ORGANIZATION workspace=$TF_WORKSPACE"
if [[ "$SOURCED" -eq 0 ]]; then
  echo "Run 'source scripts/setup.sh' to export them into your current shell."
fi
