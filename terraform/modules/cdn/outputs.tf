output "distribution_id" {
  description = "CloudFront distribution ID (needed for cache invalidation)"
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_arn" {
  description = "CloudFront distribution ARN"
  value       = aws_cloudfront_distribution.site.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront-assigned domain (*.cloudfront.net)"
  value       = aws_cloudfront_distribution.site.domain_name
}
