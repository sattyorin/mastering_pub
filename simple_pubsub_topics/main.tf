resource "google_pubsub_topic" "simple_pubsub_topics" {
  for_each = var.simple_pubsub_topics

  project                    = var.project_id
  name                       = each.value.name
  kms_key_name               = each.value.kms_key_name
  labels                     = each.value.labels
  message_retention_duration = each.value.message_retention_duration

  # ingestion_data_source_settings {} # ingestion は想定しない

  message_storage_policy {
    allowed_persistence_regions = each.value.message_storage_policy.allowed_persistence_regions
    enforce_in_transit          = true # Pub/Sub の API 呼び出し場所も allowed_persistence_regions に従う
  }

  dynamic "schema_settings" {
    for_each = each.value.schema_settings == null ? [] : [each.value.schema_settings]
    content {
      encoding = schema_settings.value.encoding
      schema   = schema_settings.value.schema
    }
  }

}
