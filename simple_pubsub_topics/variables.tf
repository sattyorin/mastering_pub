variable "project_id" {
  type = string
}

variable "simple_pubsub_topics" {
  type = map(object({
    name                       = string
    kms_key_name               = optional(string)
    labels                     = map(string)
    message_retention_duration = string
    message_storage_policy = object({
      allowed_persistence_regions = list(string)
    })
    schema_settings = optional(object({
      encoding = string
      schema   = string
    }), null)
  }))
}

