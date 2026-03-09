# ╔═══════════════════════════════════════════════════════════════╗
# ║  AWS Legacy Stack – S3 + CloudFront (OAC) + ACM + Cloudflare DNS ║
# ╚═══════════════════════════════════════════════════════════════╝

module "storage" {
  source      = "./modules/storage"
  bucket_name = var.bucket_name
}

# ACM + Cloudflare DNS validation records.
# aws.us_east_1 must be passed explicitly because CloudFront requires
# TLS certificates in us-east-1, regardless of where other resources live.
module "certificate" {
  source = "./modules/certificate"
  providers = {
    aws.us_east_1 = aws.us_east_1
    cloudflare    = cloudflare
  }
  domain_name        = var.domain_name
  cloudflare_zone_id = var.cloudflare_zone_id
}

module "cdn" {
  source                      = "./modules/cdn"
  bucket_name                 = var.bucket_name
  bucket_id                   = module.storage.bucket_id
  bucket_arn                  = module.storage.bucket_arn
  bucket_regional_domain_name = module.storage.bucket_regional_domain_name
  domain_name                 = var.domain_name
  default_root_object         = var.default_root_object
  certificate_arn             = module.certificate.certificate_arn
}

module "dns" {
  source                 = "./modules/dns"
  cloudflare_zone_id     = var.cloudflare_zone_id
  domain_name            = var.domain_name
  cloudfront_domain_name = module.cdn.cloudfront_domain_name
}

module "ci" {
  source                      = "./modules/ci"
  github_repo                 = var.github_repo
  bucket_arn                  = module.storage.bucket_arn
  cloudfront_distribution_arn = module.cdn.distribution_arn
}
