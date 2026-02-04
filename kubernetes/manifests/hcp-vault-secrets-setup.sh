#!/bin/bash
# Script to populate HCP Vault with secrets for the Pong application

set -e

echo "==================================="
echo "HCP Vault Secrets Setup"
echo "==================================="
echo ""

# Prompt for HCP Vault details
read -p "Enter your HCP Vault URL: " HCP_VAULT_ADDR
read -p "Enter your HCP Vault namespace (leave empty if not using): " HCP_VAULT_NAMESPACE
read -sp "Enter your HCP Vault token: " HCP_VAULT_TOKEN
echo ""

export VAULT_ADDR="$HCP_VAULT_ADDR"
export VAULT_TOKEN="$HCP_VAULT_TOKEN"

if [ -n "$HCP_VAULT_NAMESPACE" ]; then
  export VAULT_NAMESPACE="$HCP_VAULT_NAMESPACE"
fi

# Test connection
echo "Testing connection to HCP Vault..."
vault status || { echo "Failed to connect to HCP Vault"; exit 1; }

# Prompt for secrets
echo ""
echo "Enter the following secrets for your application:"
echo ""

read -p "Centrifugo API Key: " CENTRIFUGO_API_KEY
read -sp "Centrifugo Secret: " CENTRIFUGO_SECRET
echo ""
read -p "Redis Endpoint (from Terraform output): " REDIS_ENDPOINT
read -sp "Cloudflare Tunnel Token (optional, press Enter to skip): " CLOUDFLARE_TOKEN
echo ""

# Write backend secrets
echo "Writing backend secrets to HCP Vault..."
vault kv put secret/pong/backend \
  centrifugo_api_key="$CENTRIFUGO_API_KEY" \
  centrifugo_secret="$CENTRIFUGO_SECRET" \
  redis_url="redis://${REDIS_ENDPOINT}:6379/0"

# Write centrifugo secrets
echo "Writing centrifugo secrets to HCP Vault..."
vault kv put secret/pong/centrifugo \
  token_hmac_secret_key="$CENTRIFUGO_SECRET" \
  api_key="$CENTRIFUGO_API_KEY" \
  redis_address="redis://${REDIS_ENDPOINT}:6379/0"

# Write cloudflare secrets if provided
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "Writing cloudflare secrets to HCP Vault..."
  vault kv put secret/pong/cloudflare \
    tunnel_token="$CLOUDFLARE_TOKEN"
fi

echo ""
echo "✅ Secrets populated successfully in HCP Vault!"
echo ""
echo "Verify secrets:"
echo "  vault kv get secret/pong/backend"
echo "  vault kv get secret/pong/centrifugo"
if [ -n "$CLOUDFLARE_TOKEN" ]; then
  echo "  vault kv get secret/pong/cloudflare"
fi
echo ""
echo "Next step: Deploy your application via FluxCD (commit and push)"
