#!/usr/bin/env bash
# ============================================================
# setup-local.sh
# Sets up local development environment.
# Prerequisites: Node.js 20+, Azure Functions Core Tools v4,
#                Azure CLI, Azurite (or Azure Storage Emulator)
# ============================================================
set -euo pipefail

echo "==> Checking prerequisites..."

command -v node  >/dev/null 2>&1 || { echo "ERROR: Node.js not found. Install from https://nodejs.org"; exit 1; }
command -v func  >/dev/null 2>&1 || { echo "ERROR: Azure Functions Core Tools not found. Run: npm i -g azure-functions-core-tools@4 --unsafe-perm true"; exit 1; }
command -v az    >/dev/null 2>&1 || { echo "ERROR: Azure CLI not found. Install from https://aka.ms/installazurecli"; exit 1; }

echo "  Node.js: $(node --version)"
echo "  func:    $(func --version)"
echo "  az:      $(az --version | head -1)"

echo ""
echo "==> Installing API dependencies..."
cd "$(dirname "$0")/../api"
npm install

echo ""
echo "==> Setting up local settings..."
if [ ! -f local.settings.json ]; then
  cp local.settings.json.example local.settings.json
  echo "  Created local.settings.json — fill in your Cosmos DB credentials."
  echo "  TIP: Use a free Cosmos DB account at https://portal.azure.com"
else
  echo "  local.settings.json already exists, skipping."
fi

echo ""
echo "==> All done! To start the API locally:"
echo "    cd api && npm start"
echo ""
echo "    Then open frontend/index.html in a browser."
