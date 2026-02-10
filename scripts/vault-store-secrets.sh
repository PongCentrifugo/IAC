#!/bin/bash
# Generate and store secrets in Vault for Pong application
# Requires: vault CLI installed and VAULT_ADDR, VAULT_TOKEN set

set -e

echo "========================================="
echo "Vault Secrets Setup for Pong"
echo "========================================="
echo ""

# Check if vault CLI is available
if ! command -v vault &> /dev/null; then
  echo "❌ Vault CLI not found. Install with: brew install vault"
  exit 1
fi

# Check if VAULT_ADDR is set
if [ -z "$VAULT_ADDR" ]; then
  echo "⚠️  VAULT_ADDR not set. Setting up port-forward to vault..."
  echo ""
  echo "Run this in another terminal:"
  echo "  kubectl port-forward -n vault vault-0 8200:8200"
  echo ""
  read -p "Press Enter once port-forward is running..."
  export VAULT_ADDR='http://127.0.0.1:8200'
fi

# Check if VAULT_TOKEN is set
if [ -z "$VAULT_TOKEN" ]; then
  echo "Please enter your Vault root token:"
  read -sp "VAULT_TOKEN: " VAULT_TOKEN
  export VAULT_TOKEN
  echo ""
fi

echo "Vault address: $VAULT_ADDR"
echo ""

# Prompt for Redis URL
echo "Enter Redis endpoint (e.g., pong-redis.xxxxx.cache.amazonaws.com):"
read -p "Redis host: " REDIS_HOST

REDIS_URL="redis://${REDIS_HOST}:6379"
REDIS_ADDRESS="${REDIS_HOST}:6379"

echo ""
echo "Enter Cloudflare tunnel token (for cloudflared):"
read -sp "Tunnel token: " CLOUDFLARE_TUNNEL_TOKEN
echo ""

echo ""
echo "Generating secure random secrets..."
CENTRIFUGO_API_KEY=$(openssl rand -hex 32)
# IMPORTANT: Backend and Centrifugo must share the same JWT secret
CENTRIFUGO_JWT_SECRET=$(openssl rand -hex 32)

echo "✅ Secrets generated"
echo ""
echo "Storing secrets in Vault..."
echo ""

# Backend secrets
echo "📦 Storing backend secrets..."
vault kv put secret/pong/backend \
  centrifugo_api_key="${CENTRIFUGO_API_KEY}" \
  centrifugo_secret="${CENTRIFUGO_JWT_SECRET}" \
  redis_url="${REDIS_URL}"

echo "✅ Backend secrets stored"
echo ""

# Centrifugo secrets  
echo "📦 Storing Centrifugo secrets..."
vault kv put secret/pong/centrifugo \
  token_hmac_secret_key="${CENTRIFUGO_JWT_SECRET}" \
  api_key="${CENTRIFUGO_API_KEY}" \
  redis_address="${REDIS_ADDRESS}"

echo "✅ Centrifugo secrets stored"
echo ""

# Cloudflare secrets
echo "📦 Storing Cloudflare secrets..."
vault kv put secret/pong/cloudflare \
  tunnel_token="${CLOUDFLARE_TUNNEL_TOKEN}"

echo "✅ Cloudflare secrets stored"
echo ""

echo "================================================"
echo "✅ All secrets stored successfully in Vault!"
echo "================================================"
echo ""
echo "Verify secrets:"
echo "  kubectl exec -n vault $VAULT_POD -- vault kv get secret/pong/backend"
echo "  kubectl exec -n vault $VAULT_POD -- vault kv get secret/pong/centrifugo"
echo ""
