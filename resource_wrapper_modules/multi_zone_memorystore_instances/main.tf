# 冗長化の方法として、 Cross Instance Replication は使わず Multi Zone を使う。

resource "google_memorystore_instance" "multi_zone_memorystore_instances" {
  for_each = var.multi_zone_memorystore_instances

  project                     = var.project_id
  authorization_mode          = each.value.authorization_mode
  deletion_protection_enabled = false
  engine_configs              = each.value.engine_configs
  engine_version              = each.value.engine_version
  instance_id                 = each.value.instance_id
  labels                      = each.value.labels
  location                    = each.value.location
  mode                        = each.value.mode
  node_type                   = each.value.node_type
  replica_count               = each.value.replica_count
  shard_count                 = each.value.shard_count
  transit_encryption_mode     = each.value.transit_encryption_mode

  dynamic "automated_backup_config" {
    for_each = each.value.automated_backup_config == null ? [] : [each.value.automated_backup_config]
    content {
      retention = automated_backup_config.value.retention
      dynamic "fixed_frequency_schedule" {
        for_each = automated_backup_config.value.fixed_frequency_schedule == null ? [] : [automated_backup_config.value.fixed_frequency_schedule]
        content {
          dynamic "start_time" {
            for_each = fixed_frequency_schedule.value.start_time == null ? [] : [fixed_frequency_schedule.value.start_time]
            content {
              hours = start_time.value.hours
            }
          }
        }
      }
    }
  }

  # cross_instance_replication_config {} # Cross Instance Replication は使わない

  dynamic "desired_psc_auto_connections" {
    for_each = each.value.desired_psc_auto_connections_map
    content {
      network    = desired_psc_auto_connections.value.network
      project_id = desired_psc_auto_connections.value.project_id
    }
  }

  # gcs_source {} # GCS との連携は想定しない

  dynamic "maintenance_policy" {
    for_each = each.value.maintenance_policy == null ? [] : [each.value.maintenance_policy]
    content {
      dynamic "weekly_maintenance_window" {
        for_each = maintenance_policy.value.weekly_maintenance_window_map
        content {
          day = weekly_maintenance_window.value.day
          dynamic "start_time" {
            for_each = weekly_maintenance_window.value.start_time == null ? [] : [weekly_maintenance_window.value.start_time]
            content {
              hours   = start_time.value.hours
              minutes = start_time.value.minutes
              nanos   = start_time.value.nanos
              seconds = start_time.value.seconds
            }
          }
        }
      }
    }
  }

  dynamic "managed_backup_source" {
    for_each = each.value.managed_backup_source == null ? [] : [each.value.managed_backup_source]
    content {
      backup = managed_backup_source.value.backup
    }
  }

  persistence_config {
    mode = value.persistence_config.mode
    dynamic "aof_config" {
      for_each = value.persistence_config.aof_config == null ? [] : [value.persistence_config.aof_config]
      content {
        append_fsync = aof_config.value.append_fsync
      }
    }
    dynamic "rdb_config" {
      for_each = value.persistence_config.rdb_config == null ? [] : [value.persistence_config.rdb_config]
      content {
        rdb_snapshot_period     = rdb_config.value.rdb_snapshot_period
        rdb_snapshot_start_time = rdb_config.value.rdb_snapshot_start_time
      }
    }
  }

  zone_distribution_config {
    mode = "MULTI_ZONE"
    zone = each.value.distribution_zone
  }
}
