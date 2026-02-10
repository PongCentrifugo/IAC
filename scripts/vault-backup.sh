#!/bin/bash
# Create Vault snapshot backup and upload to S3

set -e

echo "========================================="
echo "Vault Backup (Raft Snapshot)"
echo "========================================="
echo ""

# Configuration
VAULT_POD="vault-0"
VAULT_NAMESPACE="vault"
BACKUP_BUCKET="${VAULT_BACKUP_BUCKET:-pong-vault-backups}"  # Can be overridden via env var
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="vault-snapshot-${TIMESTAMP}.snap"
REGION="${AWS_REGION:-eu-south-2}"

# Check if root token is provided
if [ -z "$VAULT_TOKEN" ]; then
  echo "Please provide Vault root token:"
  read -sp "Root token: " VAULT_TOKEN
  echo ""
fi

echo "Creating Raft snapshot..."
kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- env VAULT_TOKEN="$VAULT_TOKEN" \
  vault operator raft snapshot save /tmp/snapshot.snap

echo "Downloading snapshot from pod..."
kubectl cp $VAULT_NAMESPACE/$VAULT_POD:/tmp/snapshot.snap "./$BACKUP_FILE"

echo "Cleaning up pod..."
kubectl exec -n $VAULT_NAMESPACE $VAULT_POD -- rm /tmp/snapshot.snap

echo "✅ Snapshot created: $BACKUP_FILE"
echo ""

# Upload to S3
echo "Uploading to S3..."
echo "Bucket: $BACKUP_BUCKET"
echo "Region: $REGION"

# Check if bucket exists, create if not
if ! aws s3 ls "s3://${BACKUP_BUCKET}" --region $REGION 2>/dev/null; then
  echo "Creating S3 bucket: $BACKUP_BUCKET"
  aws s3 mb "s3://${BACKUP_BUCKET}" --region $REGION
  
  # Enable versioning
  aws s3api put-bucket-versioning \
    --bucket $BACKUP_BUCKET \
    --versioning-configuration Status=Enabled \
    --region $REGION
  
  # Enable encryption
  aws s3api put-bucket-encryption \
    --bucket $BACKUP_BUCKET \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}' \
    --region $REGION
fi

# Upload snapshot
aws s3 cp "./$BACKUP_FILE" "s3://${BACKUP_BUCKET}/${BACKUP_FILE}" --region $REGION

echo "✅ Uploaded to S3: s3://${BACKUP_BUCKET}/${BACKUP_FILE}"
echo ""

# Optional: Keep local copy or delete
read -p "Keep local snapshot file? (y/n): " KEEP_LOCAL
if [ "$KEEP_LOCAL" != "y" ]; then
  rm "./$BACKUP_FILE"
  echo "Local snapshot deleted"
fi

echo ""
echo "========================================="
echo "Backup Complete"
echo "========================================="
echo ""
echo "To restore from this snapshot:"
echo "1. kubectl exec -n vault vault-0 -- env VAULT_TOKEN=\$VAULT_TOKEN vault operator raft snapshot restore /tmp/snapshot.snap"
echo ""
echo "To list all backups:"
echo "aws s3 ls s3://${BACKUP_BUCKET}/ --region $REGION"
echo ""
