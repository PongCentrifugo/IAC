output "cloudfront_domain" {
  value       = aws_cloudfront_distribution.frontend.domain_name
  description = "CloudFront domain for frontend."
}

output "backend_ecr_repository" {
  value       = aws_ecr_repository.backend.repository_url
  description = "ECR repository for backend image."
}

output "centrifugo_ecr_repository" {
  value       = aws_ecr_repository.centrifugo.repository_url
  description = "ECR repository for Centrifugo image (optional)."
}

output "redis_endpoint" {
  value       = aws_elasticache_cluster.redis.cache_nodes[0].address
  description = "Redis endpoint."
}

output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS cluster name."
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS cluster endpoint."
}

output "eks_cluster_certificate_authority" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "EKS cluster certificate authority data."
  sensitive   = true
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID."
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "IAM Role ARN for GitHub Actions OIDC."
}

output "frontend_bucket_name" {
  value       = aws_s3_bucket.frontend.bucket
  description = "Frontend S3 bucket."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID."
}
