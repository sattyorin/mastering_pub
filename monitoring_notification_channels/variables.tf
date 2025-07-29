variable "project_id" {
  type = string
}

variable "monitoring_notification_channels" {
  type = map(object({
    description  = string
    display_name = string
    enabled      = bool
    labels       = map(string)
    type         = string # "email", "pubsub", etc.
    user_labels  = optional(map(string))

    sensitive_labels = optional(object({
      auth_token  = string
      password    = string
      service_key = string
    }), null)

  }))
}

