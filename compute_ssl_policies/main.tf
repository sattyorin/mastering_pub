variable "project_id" {
  type = string
}

variable "compute_ssl_policies" {
  type = map(object({
    name            = string
    description     = string
    custom_features = list(string)
    min_tls_version = string
    profile         = string
  }))
}

resource "google_compute_ssl_policy" "compute_ssl_policies" {
  for_each = var.compute_ssl_policies

  project         = var.project_id
  name            = each.value.name
  description     = each.value.description
  custom_features = each.value.custom_features
  min_tls_version = each.value.min_tls_version
  profile         = each.value.profile
}
