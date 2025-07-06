resource "google_compute_forwarding_rule" "psc_forwarding_rules" {
  for_each = var.psc_forwarding_rules

  project                 = var.project_id
  name                    = each.value.name
  description             = each.value.description
  all_ports               = false # ports を指定する
  allow_global_access     = false # 同一リージョン内でのアクセス以外は許可しない
  allow_psc_global_access = false # 同一リージョン内でのアクセス以外は許可しない
  backend_service         = null  # must be omitted
  ip_address              = each.value.ip_address
  ip_collection           = null # IPv6 は使用しない
  ip_protocol             = each.value.ip_protocol
  ip_version              = "IPV4"
  is_mirroring_collector  = false # This can only be set to true for load balancers that have their loadBalancingScheme set to INTERNAL.
  labels                  = each.value.labels
  load_balancing_scheme   = ""   # empty string value ("") is also supported for PSC
  network                 = null # Subnet を指定する
  network_tier            = "PREMIUM"
  no_automate_dns_zone    = true
  port_range              = null # ports を指定する
  ports                   = each.value.ports
  recreate_closed_psc     = each.value.recreate_closed_psc
  region                  = each.value.region
  service_label           = each.value.service_label
  source_ip_ranges        = each.value.source_ip_ranges
  subnetwork              = each.value.subnetwork
  target                  = each.value.target

  dynamic "service_directory_registrations" {
    for_each = each.value.service_directory_registrations == null ? [] : [each.value.service_directory_registrations]
    content {
      namespace = service_directory_registrations.value.namespace
      service   = service_directory_registrations.value.service
    }
  }

}
