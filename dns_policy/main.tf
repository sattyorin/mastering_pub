resource "google_dns_policy" "dns_policy" {
  project                   = var.project_id
  name                      = var.name
  description               = var.description
  enable_inbound_forwarding = var.enable_inbound_forwarding
  enable_logging            = true

  dynamic "alternative_name_server_config" {
    for_each = var.target_name_servers_map == null ? [] : [0]
    content {
      dynamic "target_name_servers" {
        for_each = var.target_name_servers_map
        content {
          forwarding_path = target_name_servers.value.forwarding_path
          ipv4_address    = target_name_servers.value.ipv4_address
        }
      }
    }
  }

  dynamic "networks" {
    for_each = var.networks_url_list
    content {
      network_url = networks.value
    }
  }

}
