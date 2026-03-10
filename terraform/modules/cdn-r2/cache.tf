terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.20, < 5.0"
    }
  }
}

# Cache static assets aggressively, revalidate HTML on every request.
# Replaces CloudFront default_cache_behavior + Managed-CachingOptimized policy.
resource "cloudflare_ruleset" "cache_rules" {
  zone_id = var.cloudflare_zone_id
  name    = "R2 Cache Rules"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  # Rule 1: Cache static assets for 1 year.
  # Content-hashed filenames from the Astro build make this safe.
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        mode    = "override_origin"
        default = 31536000
      }
      browser_ttl {
        mode    = "override_origin"
        default = 31536000
      }
    }
    expression  = "(http.request.uri.path.extension in {\"js\" \"css\" \"jpg\" \"jpeg\" \"png\" \"gif\" \"svg\" \"webp\" \"avif\" \"woff\" \"woff2\" \"ico\"})"
    description = "Cache static assets for 1 year"
    enabled     = true
  }

  # Rule 2: Revalidate HTML on every request.
  # Uses respect_origin mode so Cloudflare honours the Cache-Control headers
  # set during deploy (max-age=0, must-revalidate). Deploys are visible immediately.
  rules {
    action = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        mode = "respect_origin"
      }
      browser_ttl {
        mode = "respect_origin"
      }
    }
    expression  = "(http.request.uri.path.extension eq \"html\" or http.request.uri.path eq \"/\")"
    description = "Revalidate HTML on every request"
    enabled     = true
  }
}
