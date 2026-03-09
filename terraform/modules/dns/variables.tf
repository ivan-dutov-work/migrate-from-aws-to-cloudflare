variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "The custom domain to point at CloudFront"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "CloudFront-assigned domain (*.cloudfront.net)"
  type        = string
}
