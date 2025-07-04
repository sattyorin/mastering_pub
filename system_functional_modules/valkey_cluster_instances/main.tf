module "valkey_instances" {
  source = "../../resource_wrapper_modules/multi_zone_memorystore_instances"

  project_id = var.project_id

  multi_zone_memorystore_instances = {
    for key, value in var.valkey_cluster_instances : key => {
      authorization_mode      = "IAM_AUTH"
      engine_configs          = {}
      engine_version          = "VALKEY_8_0"
      instance_id             = value.instance_id
      labels                  = value.labels
      location                = "asia-northeast1"
      mode                    = "CLUSTER"
      node_type               = "SHARED_CORE_NANO"
      replica_count           = 1
      shard_count             = 1
      transit_encryption_mode = "TRANSIT_ENCRYPTION_DISABLED"

      automated_backup_config = {} # 自動バックアップはしない
      desired_psc_auto_connections_map = {
        "primary" = {
          project_id = var.project_id
          network    = var.network_id
        }
      }
      maintenance_policy = {
        weekly_maintenance_window_map = {
          "monday" = {
            day = "MONDAY"
            start_time = {
              hours   = 0
              minutes = 0
              nanos   = 0
              seconds = 0
            }
          }
        }
      }
      managed_backup_source = null
      persistence_config = {
        mode = "DISABLED"
      }
      distribution_zone = null # 指定しない
    }
  }
}
