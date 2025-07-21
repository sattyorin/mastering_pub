output "ids" {
  value = { for key, value in resource.google_certificate_manager_certificate_map.certificate_manager_certificate_maps : key => value.id }
}
