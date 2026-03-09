variable "github_repo" {
  description = "GitHub repository (e.g., owner/repo-name)"
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the S3 bucket the CI job deploys to"
  type        = string
}

variable "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution the CI job invalidates"
  type        = string
}
