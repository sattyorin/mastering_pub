variable "project_id" {
  type = string
}

module "pubsub_schemas" {
  source = "../../resource_wrapper_modules/pubsub_schema"

  project_id = var.project_id
  pubsub_schemas = {
    "email_notification_schema" = {
      name       = "email-notification-schema"
      type       = "TYPE_UNSPECIFIED"
      definition = ""
    }
  }
}

module "pubsub_topics" {
  source = "../../resource_wrapper_modules/pubsub_topics"

  project_id    = var.project_id
  pubsub_topics = {} # TODO(sara): Resource Wrapper Modules を実装する
}


module "notification_channels" {
  source = "../../resource_wrapper_modules/monitoring_notification_channels"

  project_id = var.project_id
  monitoring_notification_channels = {
    "email" = {
      description  = "Email notification channel"
      display_name = "Email Notifications"
      enabled      = true
      labels       = { email_address = "hoge@hoge.com" }
      type         = "email"
    },
    "pubsub" = {
      description  = "Pub/Sub notification channel"
      display_name = "Pub/Sub Notifications"
      enabled      = true
      labels       = {} # Pub/Sub の設定をここですると予想
      type         = "pubsub"
    }
  }
}
