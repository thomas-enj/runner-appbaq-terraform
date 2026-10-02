#!/usr/bin/env bash
set -euo pipefail

export OWNER="${OWNER:-thomas-enjalbert}"
export RG_BACKEND="${RG_BACKEND:-tenjalbertRG}"
export SA_BACKEND="${SA_BACKEND:-ststate${OWNER//-/}}"
export LOCATION="${LOCATION:-francecentral}"
export CONTAINER_BACKEND="${CONTAINER_BACKEND:-tfstate-appbaq}"
STATE_KEY="${OWNER}.runner.terraform.tfstate"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TF_ROOT="${SCRIPT_DIR}/terraform/modules"

command -v az >/dev/null
command -v terraform >/dev/null

if [[ -s "${TF_ROOT}/terraform.tfstate" ]]; then
  printf '%s\n' "Local state detected. Verify that it belongs to this runner before explicitly migrating it to ${STATE_KEY}." >&2
  exit 1
fi

RG_EXISTS="$(az group exists --name "$RG_BACKEND" --output tsv)"
if [[ "$RG_EXISTS" == "false" ]]; then
  az group create --name "$RG_BACKEND" --location "$LOCATION" --output none
elif [[ "$RG_EXISTS" != "true" ]]; then
  printf '%s\n' "Unable to determine whether the backend resource group exists." >&2
  exit 1
fi

EXISTING_ACCOUNT="$(az storage account list \
  --resource-group "$RG_BACKEND" \
  --query "[?name=='${SA_BACKEND}'].name | [0]" \
  --output tsv)"

if [[ -z "$EXISTING_ACCOUNT" ]]; then
  az storage account create \
    --name "$SA_BACKEND" \
    --resource-group "$RG_BACKEND" \
    --location "$LOCATION" \
    --sku Standard_LRS \
    --output none
fi

az storage container create \
  --name "$CONTAINER_BACKEND" \
  --account-name "$SA_BACKEND" \
  --auth-mode login \
  --output none

terraform -chdir="$TF_ROOT" init \
  -input=false \
  -reconfigure \
  -backend-config="resource_group_name=${RG_BACKEND}" \
  -backend-config="storage_account_name=${SA_BACKEND}" \
  -backend-config="container_name=${CONTAINER_BACKEND}" \
  -backend-config="key=${STATE_KEY}" \
  -backend-config="use_azuread_auth=true"

printf 'Runner state backend: %s/%s/%s\n' "$SA_BACKEND" "$CONTAINER_BACKEND" "$STATE_KEY"