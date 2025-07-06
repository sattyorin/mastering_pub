locals {
  resource_prefix = "production"
  restricted_vips = [
    "199.36.153.4",
    "199.36.153.5",
    "199.36.153.6",
    "199.36.153.7",
  ]
  private_vips = [
    "199.36.153.8",
    "199.36.153.9",
    "199.36.153.10",
    "199.36.153.11",
  ]
  iap_range = "35.235.240.0/20"

  kubernetes_service_accounts = [
    {
      name      = "serviceaccount-01"
      namespace = "production-01"
    }
  ]
}

# VPC およびその VPC への接続に必要なリソースを作成
module "production_networks" {
  source = "../../system_functional_modules/networks"

  project_id     = var.project_id
  hub_project_id = var.hub_project_id
  hub_network    = var.hub_network
  vpc_name       = "${local.resource_prefix}-vpc"
}

module "production_valkey_instances" {
  source = "../../system_functional_modules/valkey_cluster_instances"

  project_id        = var.project_id
  network_id        = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  subnet_name       = "${local.resource_prefix}-memorystore-subnet"
  subnet_cidr_range = var.subnet_cidr_range
  valkey_cluster_instances = {
    "valkey" = {
      instance_id       = "valkey"
      labels            = {}
      address_discovery = var.valkey_address_discovery
      address_primary   = var.valkey_address_primary
      dns_display_name  = "valkey-${var.project_id}-internal"  # TODO(sara): 適切な DNS 名を設定する
      dns_name          = "valkey.${var.project_id}.internal." # TODO(sara): 適切な DNS 名を設定する
      dns_a_record_name = "valkey.${var.project_id}.internal." # TODO(sara): 適切な DNS 名を設定する
    }
  }
}

module "production_postgresql_instances" {
  source = "../../system_functional_modules/postgresql_psa_instances"

  project_id = var.project_id
  network_id = module.production_networks.network_id
  postgresql_instances = {
    "postgresql" = {
      subnet_cidr_range    = var.postgresql_subnet_cidr_range
      address              = var.postgresql_address
      instance_name        = "postgresql"
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
      dns_name          = "postgresql-${var.project_id}-internal"  # TODO(sara): 適切な DNS 名を設定する
      dns_display_name  = "postgresql-${var.project_id}-internal"  # TODO(sara): 適切な DNS 名を設定する
      dns_a_record_name = "postgresql.${var.project_id}.internal." # TODO(sara): 適切な DNS 名を設定する
    }
  }
}

module "production_application_custom_roles" {
  source = "../../resource_wrapper_modules/project_iam_custom_roles"

  project_id = var.project_id
  project_iam_custom_roles = {
    "gke_autopilot" = {
      role_id     = "gke.autopilot"
      description = "Custom role for GKE Autopilot"
      permissions = [
        "autoscaling.sites.writeMetrics",
        "logging.logEntries.create",
        "monitoring.metricDescriptors.create",
        "monitoring.metricDescriptors.list",
        "monitoring.timeSeries.create",
        "monitoring.timeSeries.list",
        "iam.serviceAccounts.actAs",
        "iam.serviceAccounts.get",
        "iam.serviceAccounts.list",
        "serviceusage.services.use",
      ]
    },
  }
}

module "production_service_account" {
  source = "../../resource_wrapper_modules/service_accounts"

  project_id = var.project_id
  service_accounts = {
    "gke" = {
      account_unique_id = "${var.environment}-gke"
      description       = "Service account for GKE"
      disabled          = false
    }
  }
}

module "production_custom_role_bindings" {
  source = "../../resource_wrapper_modules/project_iam_bindings"

  project_id = var.project_id
  project_iam_bindings = {
    "gke_autopilot" = {
      role = module.application_custom_roles.names["gke_autopilot"]
      members = [
        module.service_account.members["gke"],
      ]
    }
  }
}

module "production_gke_private_endpoint_subnet" {
  source = "../../resource_wrapper_modules/compute_ipv4_subnetworks"

  project_id = var.project_id
  network_id = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  compute_ipv4_subnetworks = {
    "${local.resource_prefix}_private_endpoint_subnet" = {
      name                     = "${local.resource_prefix}-private-endpoint-subnet"
      description              = "Subnet for GKE Autopilot Cluster Private Endpoint"
      purpose                  = "PRIVATE"
      private_ip_google_access = true

      ip_cidr_range = var.master_ipv4_cidr_block

      log_config = {
        aggregation_interval = "INTERVAL_30_SEC"
        filter_expr          = null
        metadata             = "INCLUDE_ALL_METADATA"
      }

      secondary_ip_range_map = {}
    }
  }
}

module "production_gke_gateway_subnet" {
  source = "../../resource_wrapper_modules/compute_ipv4_subnetworks"

  project_id = var.project_id
  network_id = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  compute_ipv4_subnetworks = {
    "${local.resource_prefix}_gateway_subnet" = {
      name                     = "${local.resource_prefix}-gateway-subnet"
      description              = "Subnet for GKE Autopilot Cluster Gateway Endpoint"
      purpose                  = "PRIVATE"
      private_ip_google_access = true

      ip_cidr_range = var.gateway_ip_cidr_range

      log_config = {
        aggregation_interval = "INTERVAL_30_SEC"
        filter_expr          = null
        metadata             = "INCLUDE_ALL_METADATA"
      }

      secondary_ip_range_map = {}
    }
  }
}

module "production_gke_autopilot_clusters" {
  source = "../../system_functional_modules/gke_autopilot_clusters"

  project_id = var.project_id
  network_id = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  gke_autopilot_clusters = {
    "primary_dmz_cluster" = {
      cluster_name                = "primary-dmz-cluster"
      service_account_email       = module.service_account.emails["gke"]
      subnet_ip_cidr_range        = var.primary_dmz.subnet_ip_cidr_range
      pod_ip_cidr_range           = var.primary_dmz.pod_ip_cidr_range
      service_ip_cidr_range       = var.primary_dmz.service_ip_cidr_range
      master_ipv4_cidr_block      = null # private_endpoint_subnetwork を指定する
      private_endpoint_subnetwork = module.private_endpoint_subnet.ids["${local.resource_prefix}_private_endpoint_subnet"]
      master_authorized_cidr_blocks = [
        {
          display_name = "management-server-range"
          cidr_block   = var.management_server_ip_cidr_range
        },
        {
          display_name = "pod-range"
          cidr_block   = var.primary_dmz.pod_ip_cidr_range
        },
        # {
        #   display_name = "iap-range"
        #   cidr_block   = local.iap_range
        # }
      ]
      resource_labels = {}
      addresses       = {}
    }
    "primary_trust_cluster" = {
      cluster_name                = "primary-trust-cluster"
      service_account_email       = module.service_account.emails["gke"]
      subnet_ip_cidr_range        = var.primary_trust.subnet_ip_cidr_range
      pod_ip_cidr_range           = var.primary_trust.pod_ip_cidr_range
      service_ip_cidr_range       = var.primary_trust.service_ip_cidr_range
      master_ipv4_cidr_block      = null # private_endpoint_subnetwork を指定する
      private_endpoint_subnetwork = module.private_endpoint_subnet.ids["${local.resource_prefix}_private_endpoint_subnet"]
      master_authorized_cidr_blocks = [
        {
          display_name = "gateway-range"
          cidr_block   = var.gateway_ip_cidr_range
        },
        {
          display_name = "management-server-range"
          cidr_block   = var.management_server_ip_cidr_range
        },
        {
          display_name = "pod-range"
          cidr_block   = var.primary_trust.pod_ip_cidr_range
        },
        # {
        #   display_name = "iap-range"
        #   cidr_block   = local.iap_range
        # }
      ]
      resource_labels = {}
      addresses = {
        "primary_trust_gateway" = {
          display_name         = "primary-trust-gateway"
          address              = var.primary_trust.gateway_address
          dns_name             = "svc.internal."
          record_name          = "primary-trust-gateway.svc.internal."
          subnetwork_self_link = module.gateway_subnet.self_links["${local.resource_prefix}_gateway_subnet"]
        }
      }
    }
  }
}


module "production_private_dns" {
  source = "../../system_functional_modules/vpc_scope_private_dns"

  project_id = var.project_id
  network_id = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  vpc_scope_private_dns = {
    "gcr_io" = {
      description = "Private Zone for *.gcr.io to Private Google Access VIP"
      dns_name    = "gcr.io."
      labels      = {}
      name        = "gcr-io-private-zone"
      dns_record_set = {
        "gcr_io_cname" = {
          name    = "*.gcr.io."
          rrdatas = ["gcr.io."]
          ttl     = 300
          type    = "CNAME"
        }
        "gcr_io_a" = {
          name    = "gcr.io."
          rrdatas = local.restricted_vips
          ttl     = 300
          type    = "A"
        }
      }
    }
    "pkg_dev" = {
      description = "Private Zone for pkg.dev to Private Google Access VIP"
      dns_name    = "pkg.dev."
      labels      = {}
      name        = "pkg-dev-private-zone"
      dns_record_set = {
        "pkg_dev_cname" = {
          name    = "*.pkg.dev."
          rrdatas = ["pkg.dev."]
          ttl     = 300
          type    = "CNAME"
        }
        "pkg_dev_a" = {
          name    = "pkg.dev."
          rrdatas = local.restricted_vips
          ttl     = 300
          type    = "A"
        }
      }
    }
    "google_apis" = {
      description = "Private Zone for *.googleapis.com to Private Google Access VIP"
      dns_name    = "googleapis.com."
      labels      = {}
      name        = "google-apis-private-zone"
      dns_record_set = {
        "google_apis_cname" = {
          name    = "*.googleapis.com."
          rrdatas = ["restricted.googleapis.com."]
          ttl     = 300
          type    = "CNAME"
        }
        "google_apis_a" = {
          name    = "restricted.googleapis.com."
          rrdatas = local.restricted_vips
          ttl     = 300
          type    = "A"
        }
      }
    }
  }
}


module "production_load_balancing" {
  source = "../../system_functional_modules/load_balancings"

  project_id                       = var.project_id
  resource_prefix                  = local.resource_prefix
  network_id                       = local.network_id
  external_loadbalancing_addresses = var.external_loadbalancing_addresses

  backend_services = {
    "hoge" = {
      name        = "hoge"
      description = "hoge"
      backend_map = {
        "zone-a" = {
          zone_suffix                 = "a"
          network_endpoint_group_name = "hoge-neg-a"
        }
        "zone-b" = {
          zone_suffix                 = "b"
          network_endpoint_group_name = "hoge-neg-b"
        }
      }
    }

  }
  url_map = {
    url_map_default_service = module.load_balancing.backend_service_ids["hoge"]
    host_rule_map = {
      "example.com" = {
        name            = "example-com"
        hosts           = ["example.com"]
        default_service = module.load_balancing.backend_service_ids["hoge"]
        path_rule_map = {
          "api" = {
            paths   = ["/api/*"]
            service = module.load_balancing.backend_service_ids["hoge"]
          }
        }
      }
    }
  }

}

module "production_application_custom_rolesrouter_nats" {
  source = "../../system_functional_modules/router_nats"

  project_id  = var.project_id
  router_key  = "${local.resource_prefix}_router_nat"
  router_name = "${local.resource_prefix}-router"
  network_id  = module.production_networks.network_ids["${local.resource_prefix}_vpc"]
  router_nats = {
    "${local.resource_prefix}_router_nat" = {
      name = "${local.resource_prefix}-router-nat"
      subnetwork_map = {
        "${local.resource_prefix}_private_endpoint_subnet" = {
          name                     = module.private_endpoint_subnet.names["${local.resource_prefix}_private_endpoint_subnet"]
          secondary_ip_range_names = null
          source_ip_ranges_to_nat  = ["ALL_IP_RANGES"]
        }
      }
    }
  }
}
