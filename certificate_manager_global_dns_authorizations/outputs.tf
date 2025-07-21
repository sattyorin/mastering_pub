output "dns_resource_records" {
  value = { for key, value in resource.google_certificate_manager_dns_authorization.certificate_manager_global_dns_authorizations : key => value.dns_resource_record }
}
