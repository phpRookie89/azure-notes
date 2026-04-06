#!/usr/bin/env bash
# ============================================================
# deploy-infra.sh
# Provisions all Azure resources using Bicep.
# Run this once to set up your environment.
# ============================================================
set -euo pipefail

# ── Config — edit these ────────────────────────────────────
RESOURCE_GROUP="rg-azure-notes"
LOCATION="eastus"
SUFFIX="azn001"      # change to something unique (e.g. your initials + 3 digits)
ENVIRONMENT="dev"

echo "==> Logging in to Azure..."
az login

echo "==> Creating resource group: $RESOURCE_GROUP"
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"

echo "==> Deploying Bicep template..."
DEPLOY_OUTPUT=$(az deployment group create \
  --resource-group "$RESOURCE_GROUP" \
  --template-file ../infra/main.bicep \
  --parameters environment="$ENVIRONMENT" suffix="$SUFFIX" location="$LOCATION" \
  --query "properties.outputs" \
  --output json)

echo ""
echo "==> Deployment complete! Outputs:"
echo "$DEPLOY_OUTPUT" | jq .

FUNC_URL=$(echo "$DEPLOY_OUTPUT" | jq -r '.functionAppUrl.value')
echo ""
echo "==> Function App URL: $FUNC_URL"
echo "    Update API_BASE in frontend/app.js to: ${FUNC_URL}/api"
