# Vault auto-unseal with AWS KMS

# KMS key for Vault auto-unseal
resource "aws_kms_key" "vault_unseal" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name = "${local.name_prefix}-vault-unseal"
  }
}

resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/${local.name_prefix}-vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# IAM policy for Vault to use KMS for unsealing
resource "aws_iam_policy" "vault_kms_unseal" {
  name        = "${local.name_prefix}-vault-kms-unseal"
  description = "Allow Vault to use KMS for auto-unseal"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = aws_kms_key.vault_unseal.arn
      }
    ]
  })
}

# OIDC provider data for EKS (for IRSA - IAM Roles for Service Accounts)
data "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# IAM role for Vault pods (IRSA)
resource "aws_iam_role" "vault" {
  name = "${local.name_prefix}-vault"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:vault:vault"
            "${replace(data.aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-vault"
  }
}

# Attach KMS policy to Vault IAM role
resource "aws_iam_role_policy_attachment" "vault_kms_unseal" {
  role       = aws_iam_role.vault.name
  policy_arn = aws_iam_policy.vault_kms_unseal.arn
}
