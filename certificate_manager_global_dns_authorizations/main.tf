resource "google_certificate_manager_dns_authorization" "certificate_manager_global_dns_authorizations" {
  for_each = var.certificate_manager_global_dns_authorizations

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  domain      = each.value.domain
  labels      = each.value.labels
  location    = null           # If not specified, "global" is used
  type        = "FIXED_RECORD" # for global resources
}
