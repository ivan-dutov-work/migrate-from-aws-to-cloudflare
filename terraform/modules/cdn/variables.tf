variable "bucket_name" {
  description = "S3 bucket name — used for origin ID and resource naming"
  type        = string
}

variable "bucket_id" {
  description = "S3 bucket ID (name) — target for the OAC bucket policy"
  type        = string
}

variable "bucket_arn" {
  description = "S3 bucket ARN — used in the bucket policy resource statement"
  type        = string
}

variable "bucket_regional_domain_name" {
  description = "S3 regional domain name — used as the CloudFront origin domain"
  type        = string
}

variable "domain_name" {
  description = "The custom domain served by this CloudFront distribution"
  type        = string
}

variable "default_root_object" {
  description = "Default document served at the root URL"
  type        = string
  default     = "index.html"
}

variable "certificate_arn" {
  description = "ARN of the validated ACM certificate (must be in us-east-1)"
  type        = string
}
