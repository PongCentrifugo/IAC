output "alb_dns_name" {
  value       = aws_lb.main.dns_name
  description = "ALB DNS name for backend and Centrifugo."
}

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

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "ECS cluster name."
}

output "ecs_backend_service" {
  value       = aws_ecs_service.backend.name
  description = "ECS backend service name."
}

output "ecs_centrifugo_service" {
  value       = aws_ecs_service.centrifugo.name
  description = "ECS Centrifugo service name."
}

output "frontend_bucket_name" {
  value       = aws_s3_bucket.frontend.bucket
  description = "Frontend S3 bucket."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.frontend.id
  description = "CloudFront distribution ID."
}
