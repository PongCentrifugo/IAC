variable "project_name" {
  type        = string
  description = "Project name prefix for AWS resources."
  default     = "pong"
}

variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "eu-south-2"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public subnets CIDRs (2)."
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private subnets CIDRs (2)."
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "centrifugo_secret" {
  type        = string
  description = "JWT secret used by backend and Centrifugo."
  sensitive   = true
}

variable "centrifugo_api_key" {
  type        = string
  description = "Centrifugo HTTP API key."
  sensitive   = true
}

variable "frontend_bucket_name" {
  type        = string
  description = "S3 bucket name for frontend assets."
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type."
  default     = "cache.t3.micro"
}

variable "github_org" {
  type        = string
  description = "GitHub organization or username (e.g., 'PongCentrifugo')."
}

variable "github_repo" {
  type        = string
  description = "GitHub repository name (e.g., 'pong-centrifugo')."
}

variable "monthly_budget_limit" {
  type        = string
  description = "Monthly AWS budget limit in USD."
  default     = "50"
}

variable "budget_alert_email" {
  type        = string
  description = "Email for budget alerts."
  default     = ""
}
