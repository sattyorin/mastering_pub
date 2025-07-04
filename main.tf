module "network_connectivity_service_connection_policies" {
  source = "../../resource_wrapper_modules/network_connectivity_service_connection_policies"

  project_id = var.project_id
  network_id = module.vpc.ids["xxx"]

  network_connectivity_service_connection_policies = {
    "gcp_memorystore" = {
      name          = "${var.resource_prefix}-gcp-memorystore-connection-policy"
      description   = "Connection policy for gcp_memorystore"
      labels        = {}
      location      = "asia-northeast1"
      service_class = "gcp-memorystore"

      psc_config = {
        limit       = 100
        subnetworks = [module.vpc.subnetworks["xxx"]]
      }
    }
  }
}

module "postgresql_instances" {
  source = "../../system_functional_modules/postgresql_psa_instances"

  project_id = var.project_id
  network_id = module.module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  postgresql_instances = {
    "postgresql" = {
      name                 = "postgresql"
      master_instance_name = null
      replica_names        = []
      root_password        = null

      settings = {
        activation_policy = "ALWAYS"
        disk_size         = 10 # GB
        edition           = "POSTGRESQL_ENTERPRISE"
        tier              = "db-custom-2-8192" # 2 vCPU, 8 GB RAM
        psa_name          = ""                 # module.production_networks.gke_clusters_connected_sql_name["${local.resource_prefix}_vpc"]
      }
    }
  }
}

module "valkey_instances" {
  source = "../../system_functional_modules/valkey_cluster_instances"

  project_id = var.project_id
  network_id = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  valkey_cluster_instances = {
    "valkey" = {
      instance_id = "valkey"
      labels      = {}
    }
  }
}
