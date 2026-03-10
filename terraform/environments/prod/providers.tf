# ─────────────────────────────────────────────────────────────
# Provider configuration
#
# CloudFront requires ACM certificates to live in us-east-1,
# regardless of where the S3 bucket is hosted. We define two
# provider aliases so the certificate is created in the correct
# region while all other resources use the default region.
# ─────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.20, < 5.0"
    }
  }

  # ── Remote State Backend (S3 + DynamoDB) ──────────────────
  # Uncomment this block AFTER deploying the state infrastructure.
  # See DEPLOYMENT_INSTRUCTIONS.md → Section 0 for setup steps.
  #
  # backend "s3" {
  #   bucket         = "gallery-terraform-state"
  #   key            = "gallery/terraform.tfstate"
  #   region         = "us-east-1"
  #   dynamodb_table = "gallery-terraform-locks"
  #   encrypt        = true
  # }
}

# Default provider – used for S3, CloudFront, Route 53, etc.
provider "aws" {
  region = "us-east-1" # simplest: co-locate everything with CloudFront
  default_tags {
    tags = var.tags
  }
}

# Explicit us-east-1 alias – used ONLY for the ACM certificate.
# If you later move the bucket to another region, CloudFront still
# needs its certificate in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
  default_tags {
    tags = var.tags
  }
}

provider "cloudflare" {
  # Reads the API token from an environment variable for security.
}