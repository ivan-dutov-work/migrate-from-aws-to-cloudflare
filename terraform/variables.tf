variable "domain_name" {
  description = "The custom domain for the website (e.g. gallery.example.com)"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for the domain"
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
