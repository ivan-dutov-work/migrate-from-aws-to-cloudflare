variable "domain_name" {
  description = "The custom domain for the website (e.g. gallery.example.com)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
}

variable "default_root_object" {
  description = "The default document served at the root URL"
  type        = string
  default     = "index.html"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project   = "gallery"
    ManagedBy = "terraform"
  }
}

variable "github_repo" {
  description = "Your GitHub repository (e.g., ivan-dutov-work/migrate-from-aws-to-cloudflare)"
  type        = string
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID (Dashboard → right sidebar on any zone page)"
  type        = string
}

variable "r2_location_hint" {
  description = "Cloudflare R2 Location Hint (e.g., 'auto' or 'ENAM')"
  type        = string
  default     = "ENAM"
}