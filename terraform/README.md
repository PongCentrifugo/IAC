## Terraform (AWS)

This folder provisions AWS infrastructure for the Pong application:

- VPC, public/private subnets, NAT
- ECS Fargate cluster with two services: backend + Centrifugo
- ALB with path-based routing
- ElastiCache Redis
- S3 + CloudFront for frontend hosting
- ECR repositories for images

### Prerequisites

- Terraform 1.6+
- AWS credentials (OIDC or access keys)

### Usage

```bash
cd iac/terraform

terraform init
terraform plan \
  -var="centrifugo_secret=YOUR_SECRET" \
  -var="centrifugo_api_key=YOUR_API_KEY" \
  -var="frontend_bucket_name=YOUR_UNIQUE_BUCKET"

terraform apply \
  -var="centrifugo_secret=YOUR_SECRET" \
  -var="centrifugo_api_key=YOUR_API_KEY" \
  -var="frontend_bucket_name=YOUR_UNIQUE_BUCKET"
```

### Outputs

After apply, Terraform outputs:

- `alb_dns_name` → Backend + Centrifugo
- `cloudfront_domain` → Frontend URL
- `backend_ecr_repository` → Push backend images here
- `cloudfront_distribution_id` → For cache invalidations

### Notes

- This uses an ALB path rule to route `/connection/*`, `/api/*`, and `/admin*` to Centrifugo.
- All other paths go to the backend.
- Secrets are injected via task definition env vars.
