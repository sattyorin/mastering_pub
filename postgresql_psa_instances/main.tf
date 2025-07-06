# PSA (Private Service Access) で使用する Subnet を作成
module "subnets" {
  source = "../../resource_wrapper_modules/compute_ipv4_subnetworks"

  project_id = var.project_id
  network_id = var.network_id
  compute_ipv4_subnetworks = {
    for key, value in var.postgresql_instances : key => {
      name                     = "${value.instance_name}-subnet"
      description              = "Subnet for ${value.instance_name}"
      purpose                  = "PRIVATE"
      private_ip_google_access = false
      ip_cidr_range            = value.subnet_cidr_range

      log_config = {
        aggregation_interval = "INTERVAL_30_SEC"
        filter_expr          = null
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  }
}

# 上記 Subnet から Instance のアドレスを確保
module "addresses" {
  source = "../../resource_wrapper_modules/compute_ipv4_addresses"

  project_id = var.project_id

  compute_ipv4_addresses = {
    for key, value in var.postgresql_instances : key => {
      name                  = "${var.vpc_name}-address"
      description           = "Address for ${value.instance_name}"
      purpose               = "PRIVATE"
      subnetworks_self_link = module.subnets.self_links["${key}"]
      region                = "asia-northeast1"
      address_type          = "INTERNAL"
      address               = value.address
      prefix_length         = null # 単一の IP アドレス
      labels                = {}
    }

  }
}

# PSA (Private Service Access) の接続を確立
module "private_service_access_connection" {
  source = "../../resource_wrapper_modules/private_service_access_connection"

  network_id = var.network_id
  reserved_peering_ranges = [
    module.addresses.ids["${key}"],
  ]
}

# PostgreSQL インスタンスを作成
module "postgresql_instances" {
  source = "../../resource_wrapper_modules/postgresql_instances"

  project_id = var.project_id
  postgresql_instances = {
    for key, value in var.postgresql_instances : key => {
      name                 = value.instance_name
      database_version     = "POSTGRES_17"
      encryption_key_name  = null # デフォルトの暗号化キーを利用する
      maintenance_version  = null # 自動で選択
      master_instance_name = value.master_instance_name
      region               = "asia-northeast1"
      replica_names        = value.replica_names
      root_password        = value.root_password

      replica_configuration = null

      replication_cluster = null

      settings = {
        activation_policy     = value.settings.activation_policy # ALWAYS or NEVER
        availability_type     = "REGIONAL"
        collation             = null                     # TODO(sara): 安全な値を確認する
        connector_enforcement = "NOT_REQUIRED"           # Cloud SQL Auth Proxy は利用しない
        disk_autoresize       = null                     # TODO(sara): 値を埋める
        disk_autoresize_limit = 0                        # TODO(sara): 値を埋める
        disk_size             = value.settings.disk_size # Disk size in GB.
        disk_type             = "PD_SSD"
        edition               = value.settings.edition
        tier                  = value.settings.tier
        user_labels           = {} # TODO(sara): これの意味を理解する

        backup_configuration = {
          enabled                        = true
          region                         = "asia-northeast1"
          point_in_time_recovery_enabled = true # point-in-time recovery (PITR): 任意の指定日時の状態を復元する機能
          start_time                     = "16:00"
          transaction_log_retention_days = 7

          backup_retention_settings = {
            retained_backups = 7
            retention_unit   = "COUNT"
          }
        }

        # connection_pool_config_map = {} # プレビュー版かつ現時点で情報が少ない

        data_cache_config = {
          data_cache_enabled = false # デフォルトは false
        }

        database_flags_map = { # TODO(sara): 整理する。
          name  = null
          value = null
        }

        # deny_maintenance_period = {} # 必要に応じて設定する

        insights_config = {
          query_insights_enabled  = true
          query_plans_per_minute  = 5
          query_string_length     = 1024
          record_application_tags = true  # sqlcommenter で tag を付与する
          record_client_address   = false # ユースケース的に情報量が増えない
        }

        ip_configuration = {
          allocated_ip_range                            = each.value.settings.psa_name
          custom_subject_alternative_names              = null  # 顧客管理の証明書 (customer-managed certificate authority) は利用しない
          enable_private_path_for_google_cloud_services = false # Google Cloud サービスへのプライベート接続は想定しない
          ipv4_enabled                                  = false # パブリック IP アドレスは利用しない
          private_network                               = var.network_id
          server_ca_mode                                = "GOOGLE_MANAGED_INTERNAL_CA"
          server_ca_pool                                = null                              # 顧客管理の証明書 (customer-managed certificate authority) は利用しない
          ssl_mode                                      = "ALLOW_UNENCRYPTED_AND_ENCRYPTED" # 暗号化されていない接続を想定

          # authorized_networks = {} # パブリック IP を利用する時のみ有効

        }

        maintenance_window = {
          day          = 5 # 0 (MONDAY) から 6 (SUNDAY)
          hour         = 15
          update_track = "stable"
        }

        password_validation_policy = null # パスワードに関する制約は設けない

      }
    }
  }
}

# PostgreSQL インスタンスに対する DNS レコードを作成
module "database_dns" {
  source     = "../vpc_scope_private_dns"
  project_id = var.project_id
  network_id = var.network_id
  vpc_scope_private_dns = {
    for key, value in var.postgresql_instances : key => {
      description = "VPC scope DNS for postgresql instances"
      dns_name    = value.dns_name
      labels      = {}
      name        = value.dns_display_name
      simple_dns_record_set = {
        name    = value.dns_a_record_name
        rrdatas = [module.addresses.ids["${value.key}"]]
        ttl     = 300
        type    = "A"
      }
    }
  }
}
