variable "project_id" {
  type = string
}

variable "user_managed_replication_secret_no_expiration" {
  type = map(object({
    annotations     = map(string)
    labels          = map(string)
    secret_id       = string
    version_aliases = map(string)
    replication = object({
      replicas_map = map(object({
        location = string
        customer_managed_encryption = optional(object({
          kms_key_name = string
        }), null)
      }))
    })

    rotation = optional(object({
      next_rotation_time = string
      rotation_period    = string
    }), null)

    topics_map = optional(map(object({
      name = string
    })), {})
  }))

}

resource "google_secret_manager_secret" "user_managed_replication_secret_no_expiration" {
  for_each = var.user_managed_replication_secret_no_expiration

  project             = var.project_id
  annotations         = each.value.annotations
  expire_time         = null # 有効期限は想定しない
  labels              = each.value.labels
  secret_id           = each.value.secret_id
  ttl                 = null # 有効期限は設定しない
  version_aliases     = each.value.version_aliases
  version_destroy_ttl = null # 有効期限は設定しない

  dynamic "replication" {
    for_each = each.value.replication == null ? [] : [each.value.replication]
    content {

      # auto {} # 自動レプリケーションは想定しない

      user_managed {
        dynamic "replicas" {
          for_each = user_managed.value.replicas_map

          content {
            location = replicas.value.location

            dynamic "customer_managed_encryption" {
              for_each = replicas.value.customer_managed_encryption == null ? [] : [replicas.value.customer_managed_encryption]
              content {
                kms_key_name = customer_managed_encryption.value.kms_key_name
              }
            }
          }

        }
      }
    }
  }

  dynamic "rotation" {
    for_each = each.value.rotation == null ? [] : [each.value.rotation]
    content {
      next_rotation_time = rotation.value.next_rotation_time
      rotation_period    = rotation.value.rotation_period
    }
  }

  dynamic "topics" {
    for_each = each.value.topics_map
    content {
      name = topics.value.name
    }
  }
}
