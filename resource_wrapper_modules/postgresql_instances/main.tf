resource "google_sql_database_instance" "postgresql_instances" {
  for_each = var.postgresql_instances

  project              = var.project_id
  name                 = each.value.name
  database_version     = each.value.database_version
  deletion_protection  = false # リソースの存在がサービスの有効化を意味する
  encryption_key_name  = each.value.encryption_key_name
  instance_type        = "CLOUD_SQL_INSTANCE"
  maintenance_version  = each.value.maintenance_version
  master_instance_name = each.value.master_instance_name # replica_configuration block must have master_instance_name set to work
  region               = each.value.region
  replica_names        = each.value.replica_names
  root_password        = each.value.root_password

  # clone {} # Clone の作成は想定しない

  dynamic "replica_configuration" {
    for_each = each.value.replica_configuration == null ? [] : [each.value.replica_configuration]
    content {
      ca_certificate            = replica_configuration.value.ca_certificate
      cascadable_replica        = null # Only supported for SQL Server database.
      client_certificate        = replica_configuration.value.client_certificate
      client_key                = replica_configuration.value.client_key
      connect_retry_interval    = replica_configuration.value.connect_retry_interval
      dump_file_path            = replica_configuration.value.dump_file_path
      failover_target           = replica_configuration.value.failover_target
      master_heartbeat_period   = replica_configuration.value.master_heartbeat_period
      password                  = replica_configuration.value.password
      ssl_cipher                = replica_configuration.value.ssl_cipher
      username                  = replica_configuration.value.username
      verify_server_certificate = replica_configuration.value.verify_server_certificate
    }
  }

  dynamic "replication_cluster" { # Switchover 用の設定
    for_each = each.value.replication_cluster == null ? [] : [each.value.replication_cluster]
    content {
      failover_dr_replica_name = replication_cluster.value.failover_dr_replica_name
    }
  }

  # restore_backup_context {} # Restoring from a backup is an imperative action and not recommended via Terraform.

  settings {
    activation_policy            = value.settings.activation_policy # ALWAYS or NEVER
    availability_type            = value.settings.availability_type
    collation                    = value.settings.collation
    connector_enforcement        = value.settings.connector_enforcement
    deletion_protection_enabled  = false # Google Cloud レベルでの保護であり、有効化すると削除ができなくなる
    disk_autoresize              = value.settings.disk_autoresize
    disk_autoresize_limit        = value.settings.disk_autoresize_limit
    disk_size                    = value.settings.disk_size
    disk_type                    = value.settings.disk_type
    edition                      = value.settings.edition
    enable_dataplex_integration  = false       # Dataplex には接続しない
    enable_google_ml_integration = false       # Vertex AI には接続しない
    pricing_plan                 = null        # can only be PER_USE ?
    retain_backups_on_delete     = "ON_DEMAND" # 削除後はバックアップを保持する
    tier                         = value.settings.tier
    time_zone                    = "Asia/Tokyo" # supported only for SQL Server
    user_labels                  = value.settings.user_labels

    # active_directory_config {} # Can only be used with SQL Server

    # advanced_machine_features {} # Only available in Cloud SQL for SQL Server instances

    dynamic "backup_configuration" {
      for_each = each.value.settings.backup_configuration == null ? [] : [each.value.settings.backup_configuration]
      content {
        binary_log_enabled             = null # Can only be used with MySQL
        enabled                        = backup_configuration.value.enabled
        location                       = backup_configuration.value.region
        point_in_time_recovery_enabled = backup_configuration.value.point_in_time_recovery_enabled
        start_time                     = backup_configuration.value.start_time
        transaction_log_retention_days = backup_configuration.value.transaction_log_retention_days
        dynamic "backup_retention_settings" {
          for_each = [backup_configuration.backup_retention_settings]
          content {
            retained_backups = backup_retention_value.settings.retained_backups
            retention_unit   = backup_retention_value.settings.retention_unit
          }
        }
      }
    }

    dynamic "connection_pool_config" {
      for_each = each.value.settings.connection_pool_config_map
      content {
        connection_pooling_enabled = connection_pool_config.value.connection_pooling_enabled
        dynamic "flags" { # pgAudit の設定など
          for_each = connection_pool_config.flags_map
          content {
            name  = flags.value.name
            value = flags.value.value
          }
        }
      }
    }

    data_cache_config {
      data_cache_enabled = value.settings.data_cache_config.data_cache_enabled
    }

    dynamic "database_flags" {
      for_each = each.value.settings.database_flags_map
      content {
        name  = database_flags.value.name
        value = database_flags.value.value
      }
    }

    dynamic "deny_maintenance_period" {
      for_each = each.value.settings.deny_maintenance_period == null ? [] : [each.value.settings.deny_maintenance_period]
      content {
        end_date   = deny_maintenance_period.value.end_date
        start_date = deny_maintenance_period.value.start_date
        time       = deny_maintenance_period.value.time
      }
    }

    dynamic "insights_config" {
      for_each = each.value.settings.insights_config == null ? [] : [each.value.settings.insights_config]
      content {
        query_insights_enabled  = insights_config.value.query_insights_enabled
        query_plans_per_minute  = insights_config.value.query_plans_per_minute
        query_string_length     = insights_config.value.query_string_length
        record_application_tags = insights_config.value.record_application_tags
        record_client_address   = insights_config.value.record_client_address
      }
    }

    ip_configuration {
      allocated_ip_range                            = value.settings.ip_configuration.allocated_ip_range
      custom_subject_alternative_names              = value.settings.ip_configuration.custom_subject_alternative_names
      enable_private_path_for_google_cloud_services = value.settings.ip_configuration.enable_private_path_for_google_cloud_services
      ipv4_enabled                                  = value.settings.ip_configuration.ipv4_enabled
      private_network                               = value.settings.ip_configuration.private_network
      server_ca_mode                                = value.settings.ip_configuration.server_ca_mode
      server_ca_pool                                = value.settings.ip_configuration.server_ca_pool
      ssl_mode                                      = value.settings.ip_configuration.ssl_mode
      dynamic "authorized_networks" {
        for_each = value.settings.ip_configuration.authorized_networks_map
        content {
          expiration_time = authorized_networks.value.expiration_time
          name            = authorized_networks.value.name
          value           = authorized_networks.value.value
        }
      }

      # psc_config {} # Private Service Connect ではなく Private Service Access を利用する

    }

    # location_preference {} # ゾーンの選択は自動で行う

    dynamic "maintenance_window" {
      for_each = each.value.settings.maintenance_window == null ? [] : [each.value.settings.maintenance_window]
      content {
        day          = maintenance_window.value.day
        hour         = maintenance_window.value.hour
        update_track = maintenance_window.value.update_track
      }
    }

    dynamic "password_validation_policy" {
      for_each = each.value.settings.password_validation_policy == null ? [] : [each.value.settings.password_validation_policy]
      content {
        complexity                  = password_validation_policy.value.complexity
        disallow_username_substring = password_validation_policy.value.disallow_username_substring
        enable_password_policy      = password_validation_policy.value.enable_password_policy
        min_length                  = password_validation_policy.value.min_length
        password_change_interval    = password_validation_policy.value.password_change_interval
        reuse_interval              = password_validation_policy.value.reuse_interval
      }
    }

    # sql_server_audit_config {} # 監査は pgAudit で行う

  }

}
