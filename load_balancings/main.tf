module "global_addresses" {
  source = "../../resource_wrapper_modules/compute_global_addresses"

  project_id = var.project_id

  compute_global_addresses = {
    for key, value in var.external_loadbalancing_addresses : key => {
      name          = value.name
      network       = null # The field cannot be specified with external address
      description   = "Address for external Load Balancing"
      purpose       = null
      address_type  = "EXTERNAL"
      address       = null # Google によって払い出された IP アドレスを使用
      prefix_length = null # 単一の IP アドレスを使用
      labels        = {}
    }
  }
}

module "forwarding_rules" {
  source = "../../resource_wrapper_modules/external_managed_global_forwarding_rules"

  project_id   = var.project_id
  target_proxy = module.target_proxies.region_target_http_proxy.id
  external_managed_global_forwarding_rules = {
    for key, value in var.external_loadbalancing_addresses : key => {
      name             = value.name
      description      = "Forwarding rule for external Load Balancing"
      ip_address       = module.global_addresses.ids["${key}"]
      ip_protocol      = "TCP"
      labels           = {}
      network          = var.network_id
      port_range       = "443"
      source_ip_ranges = value.source_ip_ranges
    }
  }
}

module "certificate_with_dns_authorization" {
  source = "../../system_functional_modules/managed_certificates_with_dns_authorization"

  project_id = var.project_id
  network_id = var.network_id
  managed_certificates_with_dns_authorization = {
    "${var.resource_prefix}" = {
      domain_display_name = var.domain_display_name
      domain              = var.domain
      labels              = {}
    }
  }
}


module "target_proxies" {
  source = "../../resource_wrapper_modules/global_target_https_proxy"

  global_target_https_proxy = {
    name                        = "${var.resource_prefix}-global-target-https-proxy"
    description                 = "HTTPS Proxy for external Load Balancing"
    certificate_map             = module.managed_certificates_with_dns_authorization.certificate_map_ids["${var.resource_prefix}"]
    http_keep_alive_timeout_sec = 0
    quic_override               = "NONE" # Google manages whether QUIC is used
    server_tls_policy           = null
    ssl_policy                  = null
    tls_early_data              = null
    url_map                     = resource.google_compute_url_map.url_map.id
  }
}

# Module 化するにはパラメータが複雑すぎるため、直接リソースを定義
resource "google_compute_url_map" "url_map" {

  project         = var.project_id
  name            = "${var.resource_prefix}-url-map"
  description     = "URL Map for external Load Balancing"
  default_service = "" # TODO(sara): backend service id

  dynamic "host_rule" {
    for_each = var.url_map.host_rule_map
    content {
      path_matcher = host_rule.value.name
      hosts        = host_rule.value.hosts
    }
  }

  dynamic "path_matcher" {
    for_each = var.url_map.host_rule_map
    content {
      name            = path_matcher.value.name
      default_service = path_matcher.value.default_service

      dynamic "path_rule" {
        for_each = path_matcher.value.path_rule_map
        content {
          paths   = path_rule.value.paths
          service = path_rule.value.service
        }
      }
    }
  }
}

module "http_health_checks" {
  source = "../../resource_wrapper_modules/http_health_checks"

  project_id = var.project_id
  http_health_checks = {
    "${var.resource_prefix}" = {
      name                = "${var.resource_prefix}-http-health-check"
      description         = "Health Check for external Load Balancing"
      check_interval_sec  = 5
      healthy_threshold   = 2
      port                = 80
      request_path        = "/"
      timeout_sec         = 5
      unhealthy_threshold = 2
    }
  }

}

module "backend_services" {
  source = "../../resource_wrapper_modules/external_managed_global_backend_services"

  project_id = var.project_id
  external_managed_global_backend_services = {
    for key, value in var.backend_services : key => {
      name                            = value.name
      description                     = value.description
      affinity_cookie_ttl_sec         = null # Cookie による Session Affinity は利用しない
      compression_mode                = "DISABLED"
      connection_draining_timeout_sec = 300
      custom_request_headers          = []
      custom_response_headers         = []
      edge_security_policy            = null # TODO(sara): 理解する
      health_checks                   = [module.http_health_checks.ids["${var.resource_prefix}"]]
      locality_lb_policy              = "ROUND_ROBIN"
      port_name                       = "http"
      protocol                        = "HTTP"
      security_policy                 = null
      service_lb_policy               = null
      session_affinity                = "NONE"
      timeout_sec                     = 30

      backend_map = {
        for backend_key, backend_value in value.backend_map : backend_key => {
          balancing_mode               = "RATE"
          capacity_scaler              = 1.0
          description                  = value.description
          group                        = "https://www.googleapis.com/compute/v1/project/${var.project_id}/zone/asia-northeast1-${backend_value.zone_suffix}/networkEndpointGroups/${backend_value.network_endpoint_group_name}"
          max_connections              = 0
          max_connections_per_endpoint = 0
          max_connections_per_instance = 0
          max_rate                     = 1000
          max_rate_per_endpoint        = 0
          max_rate_per_instance        = 0
          max_utilization              = 0
          preference                   = "DEFAULT"

          custom_metrics_map = {} # Custom Metrics は利用しない
        }
      }

      circuit_breakers   = null # Circuit Breakers は利用しない
      custom_metrics_map = {}   # Custom Metrics は利用しない
      iap                = null # IAP は設定しない

      log_config = {
        optional_fields = []
        optional_mode   = "INCLUDE_ALL_OPTIONAL"
      }

      strong_session_affinity_cookie = null # Cookie による Session Affinity Cookie は利用しない
    }
  }
}


# module "backend_services" {
# source = "../../resource_wrapper_modules/external_managed_region_backend_services"

#   project_id = var.project_id
#   external_managed_region_backend_services = {
#     for name, backend_service in var.external_managed_region_backend_services : name => {
#       name                            = backend_service.name
#       description                     = backend_service.description
#       affinity_cookie_ttl_sec         = null # Cookie による Session Affinity は利用しない
#       connection_draining_timeout_sec = 300
#       health_checks                   = backend_service.health_checks
#       locality_lb_policy              = "ROUND_ROBIN"
#       port_name                       = "http"
#       protocol                        = "HTTP"
#       region                          = "asia-northeast1"
#       session_affinity                = "NONE"
#       timeout_sec                     = 30

#       backend_map = {
#         for backend_name, backend in backend_service.backend_map : backend_name => {
#           balancing_mode               = "RATE"
#           capacity_scaler              = 1.0
#           description                  = backend.description
#           group                        = "https://www.googleapis.com/compute/v1/project/${var.project_id}/zone/asia-northeast1-${backend.zone_suffix}/networkEndpointGroups/${backend.network_endpoint_group_name}"
#           max_connections              = 0
#           max_connections_per_endpoint = 0
#           max_connections_per_instance = 0
#           max_rate                     = 1000
#           max_rate_per_endpoint        = 0
#           max_rate_per_instance        = 0
#           max_utilization              = 0

#           custom_metrics_map = {} # Custom Metrics は利用しない
#         }
#       }

#       circuit_breakers   = null # Circuit Breakers は利用しない
#       custom_metrics_map = {}   # Custom Metrics は利用しない
#       iap                = null # IAP は設定しない

#       log_config = {
#         optional_fields = []
#         optional_mode   = "INCLUDE_ALL_OPTIONAL"
#       }

#       strong_session_affinity_cookie = null # Cookie による Session Affinity Cookie は利用しない
#     }
#   }
# }
