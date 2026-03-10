# Cloudflare Worker for subdirectory index.html resolution + custom 404 pages.
#
# Replaces:
#   - CloudFront custom_error_response blocks (404 handling)
#   - CloudFront default_root_object behavior for subdirectories
#
# R2 custom domains do NOT resolve /gallery/ → /gallery/index.html
# and do NOT serve custom error pages for missing objects.
# This Worker fills both gaps.

resource "cloudflare_workers_script" "error_pages" {
  account_id = var.cloudflare_account_id
  name       = "error-pages-${replace(var.domain_name, ".", "-")}"
  module     = true

  compatibility_date = "2024-09-23"

  content = file("${path.module}/src/error_pages.js")
}

resource "cloudflare_workers_route" "error_pages" {
  zone_id     = var.cloudflare_zone_id
  pattern     = "${var.domain_name}/*"
  script_name = cloudflare_workers_script.error_pages.name
}
