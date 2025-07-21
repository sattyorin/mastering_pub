resource "google_certificate_manager_certificate" "certificate_manager_global_managed_certificates" {
  for_each = var.certificate_manager_global_managed_certificates

  project     = var.project_id
  name        = each.value.name
  description = each.value.description
  labels      = each.value.labels
  location    = null # If not specified, "global" is used
  scope       = each.value.scope

  managed {
    dns_authorizations = each.value.dns_authorizations
    domains            = each.value.domains
    issuance_config    = each.value.issuance_config
  }

  # self_managed {} # 自己管理の証明書は想定しない
}
