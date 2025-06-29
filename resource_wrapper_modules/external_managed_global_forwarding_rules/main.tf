variable "project_id" {
  type = string
}

variable "target_proxy" {
  type = string
}

variable "external_managed_global_forwarding_rules" {
  type = map(object({
    name             = string
    description      = string
    ip_address       = string
    ip_protocol      = string
    labels           = map(string)
    port_range       = string
    source_ip_ranges = optional(list(string))
    service_directory_registrations = optional(object({
      namespace                = string
      service_directory_region = string
    }))
  }))
}

resource "google_compute_global_forwarding_rule" "external_managed_global_forwarding_rules" {
  for_each = var.external_managed_global_forwarding_rules

  project               = var.project_id
  name                  = each.value.name
  description           = each.value.description
  ip_address            = each.value.ip_address
  ip_protocol           = each.value.ip_protocol
  ip_version            = "IPV4"
  labels                = each.value.labels
  load_balancing_scheme = "EXTERNAL_MANAGED"
  network               = each.value.network
  network_tier          = "PREMIUM"
  no_automate_dns_zone  = null # Private Service Connect (PSC) は使用しない
  port_range            = each.value.port_range
  source_ip_ranges      = each.value.source_ip_ranges
  subnetwork            = null # External Load Balancing では使用しない
  target                = var.target_proxy

  # metadata_filters {} # 想定外の挙動を防ぐためここでは使用しない

  dynamic "service_directory_registrations" {
    for_each = each.value.service_directory_registrations == null ? [] : [each.value.service_directory_registrations]
    content {
      namespace                = service_directory_registrations.value.namespace
      service_directory_region = service_directory_registrations.value.service_directory_region
    }
  }

}
