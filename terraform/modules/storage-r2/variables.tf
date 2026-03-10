variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
}

variable "bucket_name" {
  description = "R2 bucket name"
  type        = string
}

variable "location_hint" {
  description = "R2 location hint: ENAM, WNAM, EEUR, WEUR, APAC"
  type        = string
  default     = "ENAM"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain (required when enable_domain = true)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain to bind to the R2 bucket (required when enable_domain = true)"
  type        = string
}

variable "enable_domain" {
  description = "Whether to create the R2 custom domain binding (DNS cutover). Set to true only in Phase 4."
  type        = bool
  default     = false
}
