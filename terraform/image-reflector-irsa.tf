# AWS EBS CSI Driver for dynamic volume provisioning
# IAM role for Image Reflector Controller to access ECR

data "aws_iam_policy_document" "image_reflector_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:DescribeImages",
      "ecr:GetDownloadUrlForLayer",
      "ecr:ListImages",
    ]
    resources = [
      aws_ecr_repository.backend.arn,
      aws_ecr_repository.centrifugo.arn,
    ]
  }
}

resource "aws_iam_policy" "image_reflector_ecr" {
  name        = "${local.name_prefix}-image-reflector-ecr"
  description = "Allow Flux image-reflector-controller to scan ECR repositories"
  policy      = data.aws_iam_policy_document.image_reflector_ecr.json
}

resource "aws_iam_role" "image_reflector" {
  name = "${local.name_prefix}-image-reflector"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" = "system:serviceaccount:flux-system:image-reflector-controller"
            "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${local.name_prefix}-image-reflector"
  }
}

resource "aws_iam_role_policy_attachment" "image_reflector_ecr" {
  role       = aws_iam_role.image_reflector.name
  policy_arn = aws_iam_policy.image_reflector_ecr.arn
}
