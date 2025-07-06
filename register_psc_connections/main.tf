resource "google_memorystore_instance_desired_user_created_endpoints" "register_psc_connections" {
  for_each = var.register_psc_connections

  project = var.project_id
  name    = each.value.name
  region  = each.value.region

  desired_user_created_endpoints {
    connections {
      dynamic "psc_connection" {
        for_each = each.value.psc_connection_map
        content {
          forwarding_rule    = psc_connection.value.forwarding_rule
          ip_address         = psc_connection.value.ip_address
          network            = psc_connection.value.network
          project_id         = var.project_id
          psc_connection_id  = psc_connection.value.psc_connection_id
          service_attachment = psc_connection.value.service_attachment
        }
      }
    }
  }
}
