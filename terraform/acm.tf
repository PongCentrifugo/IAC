# ACM Certificate Data Source for CloudFront Custom Domain
# NOTE: CloudFront requires certificates to be in us-east-1 region
#       You must create the certificate in ACM us-east-1 before using

data "aws_acm_certificate" "cloudfront" {
  count = var.custom_domain != "" ? 1 : 0

  domain   = var.custom_domain
  provider = aws.us_east_1
  statuses = ["ISSUED"]
}

# Provider for us-east-1 (required for CloudFront ACM certificates)
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
