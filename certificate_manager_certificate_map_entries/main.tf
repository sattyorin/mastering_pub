resource "google_certificate_manager_certificate_map_entry" "certificate_manager_certificate_map_entries" {
  for_each = var.certificate_manager_certificate_map_entries

  project      = var.project_id
  name         = each.value.name
  certificates = each.value.certificates
  description  = each.value.description
  hostname     = each.value.hostname
  labels       = each.value.labels
  map          = each.value.map
  matcher      = each.value.matcher

}
