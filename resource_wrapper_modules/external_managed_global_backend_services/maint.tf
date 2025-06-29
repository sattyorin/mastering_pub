variable "project_id" {
  type = string
}

variable "external_managed_global_backend_services" {
  type = map(object({

    name                            = string
    description                     = string
    affinity_cookie_ttl_sec         = optional(number, null)
    compression_mode                = optional(string)
    connection_draining_timeout_sec = number
    custom_request_headers          = optional(list(string))
    custom_response_headers         = optional(list(string))
    edge_security_policy            = optional(string)
    health_checks                   = list(string)
    locality_lb_policy              = string
    port_name                       = string
    protocol                        = string
    security_policy                 = optional(string)
    service_lb_policy               = optional(string)
    session_affinity                = string
    timeout_sec                     = number

    backend_map = map(object({
      balancing_mode               = string
      capacity_scaler              = number
      description                  = string
      group                        = string
      max_connections              = optional(number)
      max_connections_per_endpoint = optional(number)
      max_connections_per_instance = optional(number)
      max_rate                     = optional(number)
      max_rate_per_endpoint        = optional(number)
      max_rate_per_instance        = optional(number)
      max_utilization              = optional(number)
      preference                   = optional(string)
      custom_metrics_map = optional(map(object({
        dry_run         = bool
        max_utilization = number
        name            = string
      })), {})
    }))

    custom_metrics_map = optional(map(object({
      dry_run = bool
      name    = string
    })), {})

    iap = optional(object({
      enabled              = bool
      oauth2_client_id     = string
      oauth2_client_secret = string
    }), null)

    log_config = object({
      optional_fields = list(string)
      optional_mode   = string
    })

    outlier_detection = optional(object({
      consecutive_errors                    = number
      consecutive_gateway_failure           = number
      enforcing_consecutive_errors          = bool
      enforcing_consecutive_gateway_failure = bool
      enforcing_success_rate                = bool
      max_ejection_percent                  = number
      success_rate_minimum_hosts            = number
      success_rate_request_volume           = number
      success_rate_stdev_factor             = number
      base_ejection_time = optional(object({
        nanos   = optional(number)
        seconds = optional(number)
      }))
      interval = optional(object({
        nanos   = optional(number)
        seconds = optional(number)
      }))
    }), null)

    strong_session_affinity_cookie = optional(object({
      name = string
      path = string
      ttl = optional(object({
        seconds = number
        nanos   = number
      }), null)
    }), null)

  }))
}

resource "google_compute_backend_service" "external_managed_global_backend_services" {
  for_each = var.external_managed_global_backend_services

  project = var.project_id

  name                            = each.value.name
  description                     = each.value.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  compression_mode                = each.value.compression_mode
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  custom_request_headers          = each.value.custom_request_headers
  custom_response_headers         = each.value.custom_response_headers
  edge_security_policy            = each.value.edge_security_policy
  enable_cdn                      = false # CDN の利用は想定しない
  health_checks                   = each.value.health_checks
  ip_address_selection_policy     = "IPV4_ONLY"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = each.value.locality_lb_policy
  port_name                       = each.value.port_name
  protocol                        = each.value.protocol
  security_policy                 = each.value.security_policy
  service_lb_policy               = each.value.service_lb_policy
  session_affinity                = each.value.session_affinity
  timeout_sec                     = each.value.timeout_sec

  dynamic "backend" {
    for_each = each.value.backend_map
    content {
      balancing_mode               = backend.value.balancing_mode
      capacity_scaler              = backend.value.capacity_scaler
      description                  = backend.value.description
      group                        = backend.value.group
      max_connections              = backend.value.max_connections
      max_connections_per_endpoint = backend.value.max_connections_per_endpoint
      max_connections_per_instance = backend.value.max_connections_per_instance
      max_rate                     = backend.value.max_rate
      max_rate_per_endpoint        = backend.value.max_rate_per_endpoint
      max_rate_per_instance        = backend.value.max_rate_per_instance
      max_utilization              = backend.value.max_utilization
      preference                   = backend.value.preference

      dynamic "custom_metrics" {
        for_each = backend.value.custom_metrics_map
        content {
          dry_run         = custom_metrics.value.dry_run
          max_utilization = custom_metrics.value.max_utilization
          name            = custom_metrics.value.name
        }
      }

    }
  }

  # cdn_policy {} # ここでは CDN の利用を想定しない

  # circuit_breakers {} # This field is applicable only when the load_balancing_scheme is set to INTERNAL_SELF_MANAGED.

  # consistent_hash {} # This field only applies if the load_balancing_scheme is set to INTERNAL_SELF_MANAGED.

  dynamic "custom_metrics" {
    for_each = each.value.custom_metrics_map
    content {
      dry_run = custom_metrics.value.dry_run
      name    = custom_metrics.value.name
    }
  }

  dynamic "iap" {
    for_each = each.value.iap == null ? [] : [each.value.iap]
    content {
      enabled              = iap.value.enabled
      oauth2_client_id     = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }

  # locality_lb_policies {} # gRPC は想定しない

  dynamic "log_config" {
    for_each = each.value.log_config == null ? [] : [each.value.log_config]
    content {
      enable          = log_config.value.enable
      optional_fields = log_config.value.optional_fields
      optional_mode   = log_config.value.optional_mode
      sample_rate     = log_config.value.sample_rate
    }
  }

  # max_stream_duration {} # This field is only allowed when the loadBalancingScheme of the backend service is INTERNAL_SELF_MANAGED.

  dynamic "outlier_detection" {
    for_each = each.value.outlier_detection == null ? [] : [each.value.outlier_detection]
    content {
      consecutive_errors                    = outlier_detection.value.consecutive_errors
      consecutive_gateway_failure           = outlier_detection.value.consecutive_gateway_failure
      enforcing_consecutive_errors          = outlier_detection.value.enforcing_consecutive_errors
      enforcing_consecutive_gateway_failure = outlier_detection.value.enforcing_consecutive_gateway_failure
      enforcing_success_rate                = outlier_detection.value.enforcing_success_rate
      max_ejection_percent                  = outlier_detection.value.max_ejection_percent
      success_rate_minimum_hosts            = outlier_detection.value.success_rate_minimum_hosts
      success_rate_request_volume           = outlier_detection.value.success_rate_request_volume
      success_rate_stdev_factor             = outlier_detection.value.success_rate_stdev_factor
      dynamic "base_ejection_time" {
        for_each = outlier_detection.value.base_ejection_time == null ? [] : [outlier_detection.value.base_ejection_time]
        content {
          nanos   = base_ejection_time.value.nanos
          seconds = base_ejection_time.value.seconds
        }
      }
      dynamic "interval" {
        for_each = outlier_detection.value.interval == null ? [] : [outlier_detection.value.interval]
        content {
          nanos   = interval.value.nanos
          seconds = interval.value.seconds
        }
      }
    }
  }

  # security_settings {} # This field is applicable to a global backend service with the load_balancing_scheme set to INTERNAL_(SELF_)MANAGED.

  dynamic "strong_session_affinity_cookie" {
    for_each = each.value.strong_session_affinity_cookie == null ? [] : [each.value.strong_session_affinity_cookie]
    content {
      name = strong_session_affinity_cookie.value.name
      path = strong_session_affinity_cookie.value.path
      dynamic "ttl" {
        for_each = strong_session_affinity_cookie.value.ttl == null ? [] : [strong_session_affinity_cookie.value.ttl]
        content {
          nanos   = ttl.value.nanos
          seconds = ttl.value.seconds
        }
      }
    }
  }

}
