variable "project_name" {
  type        = string
  description = "Project name prefix for AWS resources."
  default     = "pong"
}

variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
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

variable "backend_image" {
  type        = string
  description = "Backend container image (ECR URL or public)."
  default     = "public.ecr.aws/docker/library/golang:1.22"
}

variable "centrifugo_image" {
  type        = string
  description = "Centrifugo container image."
  default     = "centrifugo/centrifugo:v5"
}

variable "backend_port" {
  type        = number
  description = "Backend container port."
  default     = 8080
}

variable "centrifugo_port" {
  type        = number
  description = "Centrifugo container port."
  default     = 8000
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

variable "desired_count_backend" {
  type        = number
  description = "Desired ECS tasks for backend."
  default     = 1
}

variable "desired_count_centrifugo" {
  type        = number
  description = "Desired ECS tasks for Centrifugo."
  default     = 1
}

variable "redis_node_type" {
  type        = string
  description = "ElastiCache Redis node type."
  default     = "cache.t3.micro"
}
