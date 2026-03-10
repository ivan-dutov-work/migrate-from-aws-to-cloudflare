terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = ">= 4.20, < 5.0"
    }
  }
}

resource "cloudflare_r2_bucket" "site" {
  account_id = var.cloudflare_account_id
  name       = var.bucket_name
  location   = var.location_hint
}
