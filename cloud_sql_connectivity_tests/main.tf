variable "project_id" {
  type = string
}

variable "cloud_sql_connectivity_tests" {
  type = map(object({
    name        = string
    description = string
    labels      = map(string)
    protocol    = string
    round_trip  = bool
    destination = object({
      cloud_sql_instance = string
      fqdn               = optional(string)
      ip_address         = optional(string)
      network            = optional(string)
      port               = optional(number)
      project_id         = optional(string)
    })
    source = object({
      cloud_sql_instance = string
      gke_master_cluster = optional(string)
      instance           = optional(string)
      ip_address         = optional(string)
      network            = optional(string)
      network_type       = optional(string)
      port               = optional(number)
      project_id         = optional(string)
    })
  }))
}

resource "google_network_management_connectivity_test" "cloud_sql_connectivity_tests" {
  for_each = var.cloud_sql_connectivity_tests

  project                = var.project_id
  name                   = each.value.name
  description            = each.value.description
  bypass_firewall_checks = false # firewall ルールをチェック
  labels                 = each.value.labels
  protocol               = each.value.protocol
  related_projects       = null # プロジェクトを跨ぐことは想定しない
  round_trip             = each.value.round_trip

  dynamic "destination" {
    for_each = each.value.destination == null ? [] : [each.value.destination]
    content {
      cloud_sql_instance = destination.value.cloud_sql_instance
      fqdn               = destination.value.fqdn
      ip_address         = destination.value.ip_address
      network            = destination.value.network
      port               = destination.value.port
      project_id         = destination.value.project_id
      forwarding_rule    = null # Cloud SQL に限定
      gke_master_cluster = null # Cloud SQL に限定
      instance           = null # Cloud SQL に限定
      redis_cluster      = null # Cloud SQL に限定
      redis_instance     = null # Cloud SQL に限定
    }
  }

  dynamic "source" {
    for_each = each.value.source == null ? [] : [each.value.source]
    content {
      cloud_sql_instance = source.value.cloud_sql_instance
      gke_master_cluster = source.value.gke_master_cluster
      instance           = source.value.instance
      ip_address         = source.value.ip_address
      network            = source.value.network
      network_type       = source.value.network_type
      port               = source.value.port
      project_id         = source.value.project_id

      # app_engine_version {} # Cloud SQL に限定
      # cloud_function {} # Cloud SQL に限定
      # cloud_run_revision {} # Cloud SQL に限定
    }
  }

}
