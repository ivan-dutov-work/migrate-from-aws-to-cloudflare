# Security response headers — replaces aws_cloudfront_response_headers_policy.
# Injects HSTS, X-Frame-Options, X-Content-Type-Options, Referrer-Policy,
# and X-XSS-Protection on all responses via a Transform Rule.
resource "cloudflare_ruleset" "security_headers" {
  zone_id = var.cloudflare_zone_id
  name    = "Security Response Headers"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules {
    action = "rewrite"
    action_parameters {
      headers {
        name      = "Referrer-Policy"
        operation = "set"
        value     = "strict-origin-when-cross-origin"
      }

      headers {
        name      = "Strict-Transport-Security"
        operation = "set"
        value     = "max-age=31536000; includeSubDomains; preload"
      }

      headers {
        name      = "X-Content-Type-Options"
        operation = "set"
        value     = "nosniff"
      }

      headers {
        name      = "X-Frame-Options"
        operation = "set"
        value     = "DENY"
      }

      headers {
        name      = "X-XSS-Protection"
        operation = "set"
        value     = "1; mode=block"
      }
    }
    expression  = "true"
    description = "Add security response headers to all responses"
    enabled     = true
  }
}
