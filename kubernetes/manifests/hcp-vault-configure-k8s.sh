#!/bin/bash
# Script to configure HCP Vault Kubernetes authentication
# Run this after creating your HCP Vault cluster

set -e

echo "==================================="
echo "HCP Vault Kubernetes Auth Setup"
echo "==================================="
echo ""

# Prompt for HCP Vault details
read -p "Enter your HCP Vault URL (e.g., https://your-cluster.vault.11eb-xxxx.aws.hashicorp.cloud:8200): " HCP_VAULT_ADDR
read -p "Enter your HCP Vault namespace (leave empty if not using namespaces): " HCP_VAULT_NAMESPACE
read -sp "Enter your HCP Vault admin token: " HCP_VAULT_TOKEN
echo ""

export VAULT_ADDR="$HCP_VAULT_ADDR"
export VAULT_TOKEN="$HCP_VAULT_TOKEN"

if [ -n "$HCP_VAULT_NAMESPACE" ]; then
  export VAULT_NAMESPACE="$HCP_VAULT_NAMESPACE"
fi

# Test connection
echo "Testing connection to HCP Vault..."
vault status || { echo "Failed to connect to HCP Vault. Check your URL and token."; exit 1; }

# Enable Kubernetes auth method
echo "Enabling Kubernetes auth method..."
vault auth enable kubernetes 2>/dev/null || echo "Kubernetes auth already enabled"

# Get Kubernetes configuration
echo "Getting Kubernetes cluster configuration..."
KUBERNETES_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.server}')
KUBERNETES_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode)

# Create a service account for Vault in the pong namespace
echo "Creating Vault service account in pong namespace..."
kubectl create namespace pong 2>/dev/null || echo "Namespace pong already exists"

kubectl apply -f - <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: pong
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth-token
  namespace: pong
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
EOF

# Wait for secret to be created
sleep 2

# Get the service account token
echo "Getting service account token..."
SA_JWT_TOKEN=$(kubectl get secret vault-auth-token -n pong -o jsonpath='{.data.token}' | base64 --decode)

# Configure Kubernetes auth in HCP Vault
echo "Configuring Kubernetes auth in HCP Vault..."
vault write auth/kubernetes/config \
  token_reviewer_jwt="$SA_JWT_TOKEN" \
  kubernetes_host="$KUBERNETES_HOST" \
  kubernetes_ca_cert="$KUBERNETES_CA_CERT" \
  disable_local_ca_jwt=true

# Enable KV v2 secrets engine
echo "Enabling KV v2 secrets engine..."
vault secrets enable -path=secret kv-v2 2>/dev/null || echo "KV v2 already enabled"

# Create policy for pong app
echo "Creating pong-app policy..."
vault policy write pong-app - <<EOF
path "secret/data/pong/*" {
  capabilities = ["read", "list"]
}
EOF

# Create Kubernetes role for pong namespace
echo "Creating Kubernetes role for pong namespace..."
vault write auth/kubernetes/role/pong \
  bound_service_account_names=default,vault-auth \
  bound_service_account_namespaces=pong \
  policies=pong-app \
  ttl=24h

echo ""
echo "✅ HCP Vault Kubernetes authentication configured successfully!"
echo ""
echo "Next steps:"
echo "1. Update flux/infrastructure/vault-injector.yaml with your HCP Vault URL:"
echo "   externalVaultAddr: \"$HCP_VAULT_ADDR\""
echo ""
echo "2. Run ./hcp-vault-secrets-setup.sh to populate secrets"
echo ""
echo "3. Commit and push to deploy via FluxCD"
