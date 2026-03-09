terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "site_routing" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  type    = "CNAME"
  content = var.cloudfront_domain_name

  # Avoid caching — CloudFront already handles that.
  # Migration note: set proxied = true and update content to the R2/Workers
  # hostname once the Cloudflare stack is live.
  proxied = false
}
