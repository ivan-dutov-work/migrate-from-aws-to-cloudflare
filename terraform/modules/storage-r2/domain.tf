# R2 custom domain — this IS the DNS cutover.
#
# The Cloudflare Terraform provider v4 does not expose a native resource for
# R2 custom domain bindings. The binding is created via the Cloudflare API
# using a null_resource + local-exec provisioner below.
#
# What this does when enable_domain = true:
# 1. Calls the Cloudflare API to bind the custom domain to the R2 bucket
# 2. Cloudflare automatically creates a proxied DNS record (CDN + TLS + DDoS)
# 3. Immediately starts serving traffic from R2
#
# Gated behind var.enable_domain (default false).
# Set enable_domain = true only during Phase 4 (DNS cutover),
# after data migration and CI/CD switchover are complete.
#
# Prerequisites: CLOUDFLARE_API_TOKEN environment variable must be set.

resource "terraform_data" "r2_custom_domain" {
  count = var.enable_domain ? 1 : 0

  input = {
    account_id = var.cloudflare_account_id
    bucket     = cloudflare_r2_bucket.site.name
    domain     = var.domain_name
    zone_id    = var.cloudflare_zone_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -sf -X PUT \
        "https://api.cloudflare.com/client/v4/accounts/${self.input.account_id}/r2/buckets/${self.input.bucket}/custom_domains" \
        -H "Authorization: Bearer $CLOUDFLARE_API_TOKEN" \
        -H "Content-Type: application/json" \
        --data '{"domain":"${self.input.domain}","zoneId":"${self.input.zone_id}","enabled":true}'
    EOT
  }
}
