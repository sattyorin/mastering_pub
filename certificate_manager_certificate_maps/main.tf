resource "google_certificate_manager_certificate_map" "certificate_manager_certificate_maps" {
  for_each = var.certificate_manager_certificate_maps

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  labels      = each.value.labels
}
