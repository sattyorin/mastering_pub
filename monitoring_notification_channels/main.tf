resource "google_monitoring_notification_channel" "monitoring_notification_channels" {
  for_each = var.monitoring_notification_channels

  project = var.project_id

  description  = each.value.description
  display_name = each.value.display_name
  enabled      = each.value.enabled
  force_delete = true # リソースの存在がサービスの有効化を意味する
  labels       = each.value.labels
  type         = each.value.type # "email", "pubsub", etc.
  user_labels  = each.value.user_labels

  dynamic "sensitive_labels" {
    for_each = [each.value.sensitive_labels]
    content {
      auth_token  = sensitive_labels.value.auth_token
      password    = sensitive_labels.value.password
      service_key = sensitive_labels.value.service_key
    }
  }

}
