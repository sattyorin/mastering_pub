output "ids" {
  value = { for key, value in resource.google_certificate_manager_managed_certificate.certificate_manager_global_managed_certificates : key => value.id }
}
