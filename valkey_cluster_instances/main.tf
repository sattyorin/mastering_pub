locals {
  resource_key = "valkey_cluster"

  connection_type_map = { # Cluster では Discovery Endpoint と Data Endpoint の 2 種類の接続に対して設定が必要
    "discovery" = "CONNECTION_TYPE_DISCOVERY",
    "primary"   = "CONNECTION_TYPE_PRIMARY"
  }
}

# この Module で扱う Valkey クラスターに接続するための Subnet を作成
module "subnets" {
  source = "../../resource_wrapper_modules/compute_ipv4_subnetworks"

  project_id = var.project_id
  network_id = var.network_id
  compute_ipv4_subnetworks = {
    "${local.resource_key}" = {
      name                     = var.subnet_name
      description              = "Subnet for ${var.subnet_name}"
      purpose                  = "PRIVATE"
      private_ip_google_access = false
      ip_cidr_range            = var.subnet_cidr_range

      log_config = {
        aggregation_interval = "INTERVAL_30_SEC"
        filter_expr          = null
        metadata             = "INCLUDE_ALL_METADATA"
      }
    }
  }
}

# Instance に接続するアドレスを確保
module "addresses" {
  source = "../../resource_wrapper_modules/compute_ipv4_addresses"

  project_id = var.project_id

  compute_ipv4_addresses = merge([
    for key, value in var.valkey_cluster_instances : {
      for connection_type in keys(local.connection_type_map) : "${key}_${connection_type}" => {
        name                  = "${value.instance_id}-${connection_type}-address"
        description           = "Address for ${value.instance_id}"
        purpose               = "PRIVATE"
        subnetworks_self_link = module.subnets.self_links["${local.resource_key}"]
        region                = "asia-northeast1"
        address_type          = "INTERNAL"
        address               = { "discovery" = value.address_discovery, "primary" = value.address_primary }[connection_type]
        prefix_length         = null # 単一の IP アドレス
        labels                = {}
      }
    }
  ]...)
}

# Private Service Connect (PSC) の接続を確立
module "psc_forwarding_rules" {
  source = "../../resource_wrapper_modules/psc_forwarding_rules"

  project_id = var.project_id

  psc_forwarding_rules = merge([
    for key, value in var.valkey_cluster_instances : {
      for connection_type in keys(local.connection_type_map) : "${key}_${connection_type}" => {
        name                            = "${value.instance_id}-${connection_type}-forwarding-rule"
        description                     = "Valkey Cluster PSC Forwarding Rule"
        labels                          = {}
        ip_address                      = module.addresses.ids["${key}_${connection_type}"]
        ip_protocol                     = "TCP"
        ports                           = ["6379"]
        recreate_closed_psc             = value.forwarding_rules_recreate_closed_psc
        region                          = "asia-northeast1"
        service_label                   = {}
        source_ip_ranges                = value.source_ip_ranges
        subnetwork                      = module.subnets.self_links["${local.resource_key}"]
        service_directory_registrations = null
        target                          = module.valkey_instances.service_attachments["${key}"][local.connection_type_map[connection_type]]
      }
    }
  ]...)
}

# 自動で PSC エンドポイントを作成する場合は Connection Policy を作成
# WIP(sara): module としての分割や条件分岐の設計
# module "network_connectivity_service_connection_policies" {
#   source = "../../resource_wrapper_modules/network_connectivity_service_connection_policies"

#   project_id = var.project_id
#   network_id = var.network_id

#   network_connectivity_service_connection_policies = {
#     "gcp_memorystore" = {
#       name          = "gcp-memorystore-connection-policy"
#       description   = "Connection policy for memorystore"
#       labels        = {}
#       location      = "asia-northeast1"
#       service_class = "gcp-memorystore"

#       psc_config = {
#         limit       = null
#         subnetworks = [module.subnets.self_links["gcp_memorystore"]]
#       }
#     }
#   }
# }

# Valkey クラスターを作成
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

      desired_psc_auto_connections_map = null # PSC への接続は自動作成しない
      # desired_psc_auto_connections_map = { # TODO(sara): 切り替えのための変数を用意する
      #   "primary" = {
      #     project_id = var.project_id
      #     network    = var.network_id
      #   }
      # }

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

# Valkey クラスターに対する PSC 接続を登録
module "memorystore_instance_desired_user_created_endpoints" {
  source = "../../resource_wrapper_modules/register_psc_connections"

  project_id = var.project_id
  register_psc_connections = {
    for key, value in var.valkey_cluster_instances : key => {

      name   = value.instance_id
      region = "asia-northeast1"

      psc_connection_map = {
        for connection_type in keys(local.connection_type_map) : "${key}_${connection_type}" => {
          forwarding_rule    = module.psc_forwarding_rules.ids["${key}_${connection_type}"]
          ip_address         = module.addresses.ids["${key}_${connection_type}"]
          network            = var.network_id
          psc_connection_id  = module.psc_forwarding_rules.psc_connection_ids["${key}_${connection_type}"]
          service_attachment = module.valkey_instances.service_attachments["${key}"][local.connection_type_map[connection_type]]
        }
      }
    }
  }

}

# Valkey クラスターに対する DNS レコードを作成
# discovery エンドポイントの DNS レコードのみを作成する
module "dns" {
  source = "../vpc_scope_private_dns"

  project_id = var.project_id
  network_id = var.network_id
  vpc_scope_private_dns = {
    for key, value in var.valkey_cluster_instances : key => {
      description = "VPC scope DNS for Memorystore"
      dns_name    = value.dns_name
      labels      = {}
      name        = value.dns_display_name
      simple_dns_record_set = {
        name    = value.dns_a_record_name
        rrdatas = [module.addresses.ids["${value.key}_discovery"]]
        ttl     = 300
        type    = "A"
      }
    }
  }
}
