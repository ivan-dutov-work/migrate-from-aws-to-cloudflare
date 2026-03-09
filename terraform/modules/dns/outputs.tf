output "hostname" {
  description = "The fully-qualified Cloudflare DNS record hostname"
  value       = cloudflare_record.site_routing.hostname
}
