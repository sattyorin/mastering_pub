output "ids" {
  value = { for key, value in resource.google_dns_managed_zone.vpc_scope_public_dns_managed_zone : key => value.id }
}
