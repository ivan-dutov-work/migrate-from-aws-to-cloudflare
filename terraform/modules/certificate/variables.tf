variable "domain_name" {
  description = "The custom domain for the website (e.g. gallery.example.com)"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for the domain"
  type        = string
}
