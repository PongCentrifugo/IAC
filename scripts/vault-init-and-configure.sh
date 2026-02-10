#!/bin/bash
# Vault initialization and Kubernetes authentication setup
# Run this ONCE after deploying Vault cluster

set -e

echo "========================================="
echo "Vault Initialization and Setup"
echo "========================================="
echo ""

# Wait for Vault pod to be running (not Ready, as it won't be ready until initialized)
echo "Waiting for Vault pod to be running..."
TIMEOUT=300
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
  POD_STATUS=$(kubectl get pod vault-0 -n vault -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
  if [ "$POD_STATUS" == "Running" ]; then
    echo "✅ Vault pod is running"
    echo ""
    break
  fi
  sleep 5
  ELAPSED=$((ELAPSED + 5))
done

if [ $ELAPSED -ge $TIMEOUT ]; then
  echo "❌ Vault pod not running after 5 minutes. Check pod status:"
  kubectl get pods -n vault
  exit 1
fi

# Check if Vault is already initialized
echo "Checking Vault initialization status..."
VAULT_POD="vault-0"

INIT_STATUS=$(kubectl exec -n vault $VAULT_POD -- vault status -format=json 2>/dev/null | jq -r '.initialized' || echo "false")

if [ "$INIT_STATUS" == "true" ]; then
  echo "⚠️  Vault is already initialized!"
  echo ""
  read -p "Do you want to continue with configuration? (y/n): " CONTINUE
  if [ "$CONTINUE" != "y" ]; then
    echo "Exiting..."
    exit 0
  fi
else
  echo "Initializing Vault..."
  echo ""
  
  # Initialize Vault with auto-unseal (AWS KMS)
  # Note: When using auto-unseal, recovery keys are generated instead of unseal keys
  INIT_OUTPUT=$(kubectl exec -n vault $VAULT_POD -- vault operator init \
    -format=json)
  
  # Save the output
  TIMESTAMP=$(date +%Y%m%d_%H%M%S)
  OUTPUT_FILE="vault-init-keys-${TIMESTAMP}.json"
  echo "$INIT_OUTPUT" > "$OUTPUT_FILE"
  
  echo "✅ Vault initialized successfully!"
  echo ""
  echo "🔐 CRITICAL: Recovery keys and root token saved to: $OUTPUT_FILE"
  echo ""
  echo "⚠️  IMPORTANT: Store this file securely (e.g., AWS Secrets Manager, 1Password)"
  echo "⚠️  If lost, you cannot recover Vault access!"
  echo ""
  
  # Extract root token for configuration
  ROOT_TOKEN=$(echo "$INIT_OUTPUT" | jq -r '.root_token')
fi

# If we don't have ROOT_TOKEN yet (already initialized), ask for it
if [ -z "$ROOT_TOKEN" ]; then
  echo "Please provide the Vault root token for configuration:"
  read -sp "Root token: " ROOT_TOKEN
  echo ""
fi

# Export for kubectl exec commands
export VAULT_TOKEN="$ROOT_TOKEN"

echo "Configuring Vault..."
echo ""

# Get Kubernetes configuration
echo "1. Getting Kubernetes cluster configuration..."
KUBERNETES_HOST=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.server}')
KUBERNETES_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 --decode)

# Create service account for Vault auth in pong namespace
echo "2. Creating Vault service account in pong namespace..."
kubectl create namespace pong 2>/dev/null || echo "   Namespace pong already exists"

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
sleep 3

# Get the service account token
echo "3. Getting service account token..."
SA_JWT_TOKEN=$(kubectl get secret vault-auth-token -n pong -o jsonpath='{.data.token}' | base64 --decode)

# Enable Kubernetes auth method
echo "4. Enabling Kubernetes auth method..."
kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN="$ROOT_TOKEN" \
  vault auth enable kubernetes 2>/dev/null || echo "   Kubernetes auth already enabled"

# Configure Kubernetes auth
echo "5. Configuring Kubernetes auth..."
kubectl exec -i -n vault $VAULT_POD -- env VAULT_TOKEN="$ROOT_TOKEN" sh -c "
  vault write auth/kubernetes/config \
    token_reviewer_jwt='$SA_JWT_TOKEN' \
    kubernetes_host='$KUBERNETES_HOST' \
    kubernetes_ca_cert=- \
    disable_local_ca_jwt=false <<EOF
$KUBERNETES_CA_CERT
EOF
"

# Enable KV v2 secrets engine
echo "6. Enabling KV v2 secrets engine..."
kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN="$ROOT_TOKEN" \
  vault secrets enable -path=secret kv-v2 2>/dev/null || echo "   KV v2 already enabled"

# Create policy for pong app
echo "7. Creating pong-app policy..."
kubectl exec -i -n vault $VAULT_POD -- env VAULT_TOKEN="$ROOT_TOKEN" \
  vault policy write pong-app - <<'EOF'
path "secret/data/pong/*" {
  capabilities = ["read", "list"]
}
EOF

# Create Kubernetes role for pong namespace
echo "8. Creating Kubernetes role for pong namespace..."
kubectl exec -n vault $VAULT_POD -- env VAULT_TOKEN="$ROOT_TOKEN" \
  vault write auth/kubernetes/role/pong \
  bound_service_account_names=default,vault-auth \
  bound_service_account_namespaces=pong \
  policies=pong-app \
  ttl=24h

echo ""
echo "✅ Vault configuration completed successfully!"
echo ""
echo "Next steps:"
echo "1. Run ./vault-migrate-secrets.sh to migrate secrets from HCP Vault"
echo "2. Restart application deployments to use self-hosted Vault"
echo ""
