variable "project_id" {
  type = string
}

variable "multi_zone_memorystore_instances" {
  type = map(object({
    authorization_mode      = string
    engine_configs          = optional(map(string))
    engine_version          = string
    instance_id             = string
    labels                  = map(string)
    location                = string
    mode                    = string
    node_type               = string
    replica_count           = number
    shard_count             = number
    transit_encryption_mode = string

    automated_backup_config = optional(object({
      retention = number
      fixed_frequency_schedule = optional(object({
        start_time = optional(object({
          hours = number
        }))
      }))
    }), null)

    desired_psc_auto_connections_map = map(object({
      network    = string
      project_id = string
    }))

    maintenance_policy = optional(object({
      weekly_maintenance_window_map = map(object({
        day = string
        start_time = optional(object({
          hours   = number
          minutes = number
          nanos   = number
          seconds = number
        }))
      }))
    }), null)

    managed_backup_source = optional(object({
      backup = string
    }), null)

    persistence_config = object({
      mode = string
      aof_config = optional(object({
        append_fsync = string
      }), null)
      rdb_config = optional(object({
        rdb_snapshot_period = number
        rdb_snapshot_start_time = optional(object({
          hours   = number
          minutes = number
          nanos   = number
          seconds = number
        }))
      }), null)
    })

    distribution_zone = optional(string)
  }))

}
