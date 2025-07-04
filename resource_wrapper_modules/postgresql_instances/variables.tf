variable "project_id" {
  type = string
}

variable "postgresql_instances" {
  type = map(object({
    name                 = string
    database_version     = string
    encryption_key_name  = string
    maintenance_version  = string
    master_instance_name = string
    region               = string
    replica_names        = list(string)
    root_password        = string

    replica_configuration = optional(object({
      ca_certificate            = string
      client_certificate        = string
      client_key                = string
      connect_retry_interval    = string
      dump_file_path            = string
      failover_target           = bool
      master_heartbeat_period   = string
      password                  = string
      ssl_cipher                = string
      username                  = string
      verify_server_certificate = bool
    }), null)

    replication_cluster = object({
      failover_dr_replica_name = string
    })

    settings = object({
      activation_policy     = string
      availability_type     = string
      collation             = string
      connector_enforcement = bool
      disk_autoresize       = bool
      disk_autoresize_limit = number
      disk_size             = number
      disk_type             = string
      edition               = string
      tier                  = string
      user_labels           = map(string)

      backup_configuration = optional(object({
        enabled                        = bool
        region                         = string
        point_in_time_recovery_enabled = bool
        start_time                     = string
        transaction_log_retention_days = number

        backup_retention_settings = object({
          retained_backups = number
          retention_unit   = string
        })
      }), null)

      connection_pool_config_map = optional(map(object({
        connection_pooling_enabled = bool
        flags_map = map(object({
          name  = string
          value = string
        }))
      })))

      data_cache_config = object({
        data_cache_enabled = bool
      })

      database_flags_map = optional(map(object({
        name  = string
        value = string
      })))

      deny_maintenance_period = optional(object({
        end_date   = string
        start_date = string
        time       = string
      }), null)

      insights_config = optional(object({
        query_insights_enabled  = bool
        query_plans_per_minute  = number
        query_string_length     = number
        record_application_tags = bool
        record_client_address   = bool
      }), null)

      ip_configuration = object({
        allocated_ip_range                            = string
        custom_subject_alternative_names              = list(string)
        enable_private_path_for_google_cloud_services = bool
        ipv4_enabled                                  = bool
        private_network                               = string
        server_ca_mode                                = string
        server_ca_pool                                = string
        ssl_mode                                      = string

        authorized_networks_map = optional(map(object({
          expiration_time = string
          name            = string
          value           = string
        })))

      })

      maintenance_window = optional(object({
        day          = number
        hour         = number
        update_track = string
      }), null)

      password_validation_policy = optional(object({
        complexity                  = string
        disallow_username_substring = bool
        enable_password_policy      = bool
        min_length                  = number
        password_change_interval    = number
        reuse_interval              = number
      }), null)

    })
  }))

}
