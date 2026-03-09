output "s3_bucket_name" {
  description = "Name of the S3 bucket holding the site assets"
  value       = aws_s3_bucket.site.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.site.id
}

output "cloudfront_domain_name" {
  description = "CloudFront-assigned domain (*.cloudfront.net)"
  value       = aws_cloudfront_distribution.site.domain_name
}

output "website_url" {
  description = "Live website URL"
  value       = "https://${var.domain_name}"
}

output "github_actions_role_arn" {
  value       = aws_iam_role.github_actions.arn
  description = "The ARN of the IAM role for GitHub Actions to assume"
}