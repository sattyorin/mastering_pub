variable "project_id" {
  type = string
}

variable "external_managed_region_backend_services" {
  type = map(object({
    name                            = string
    description                     = string
    affinity_cookie_ttl_sec         = optional(number, null)
    connection_draining_timeout_sec = number
    health_checks                   = list(string)
    locality_lb_policy              = string
    port_name                       = string
    protocol                        = string
    region                          = string
    session_affinity                = string
    timeout_sec                     = number

    backend_map = map(object({
      balancing_mode               = string
      capacity_scaler              = number
      description                  = string
      group                        = string
      max_connections              = optional(number, null)
      max_connections_per_endpoint = optional(number, null)
      max_connections_per_instance = optional(number, null)
      max_rate                     = optional(number, null)
      max_rate_per_endpoint        = optional(number, null)
      max_rate_per_instance        = optional(number, null)
      max_utilization              = optional(number, null)
      custom_metrics_map = optional(map(object({
        dry_run         = bool
        max_utilization = number
        name            = string
      })), {})
    }))

    circuit_breakers = optional(object({
      max_connections             = number
      max_pending_requests        = number
      max_requests                = number
      max_requests_per_connection = number
      max_retries                 = number
    }), null)

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

resource "google_compute_region_backend_service" "external_managed_region_backend_services" {
  for_each = var.external_managed_region_backend_services

  project = var.project_id

  name                            = each.value.name
  description                     = each.value.description
  affinity_cookie_ttl_sec         = each.value.affinity_cookie_ttl_sec
  connection_draining_timeout_sec = each.value.connection_draining_timeout_sec
  enable_cdn                      = false # CDN の利用は想定しない
  health_checks                   = each.value.health_checks
  ip_address_selection_policy     = "IPV4_ONLY"
  load_balancing_scheme           = "EXTERNAL_MANAGED"
  locality_lb_policy              = each.value.locality_lb_policy
  network                         = null # This field can only be specified when the load balancing scheme is set to INTERNAL, or when the load balancing scheme is set to EXTERNAL and haPolicy fastIpMove is enabled.
  port_name                       = each.value.port_name
  protocol                        = each.value.protocol
  region                          = each.value.region
  session_affinity                = each.value.session_affinity
  timeout_sec                     = each.value.timeout_sec

  dynamic "backend" {
    for_each = each.value.backend_map
    content {
      balancing_mode               = backend.value.balancing_mode
      capacity_scaler              = backend.value.capacity_scaler
      description                  = backend.value.description
      failover                     = false # 内部パススルーロードバランサーのみ対象
      group                        = backend.value.group
      max_connections              = backend.value.max_connections
      max_connections_per_endpoint = backend.value.max_connections_per_endpoint
      max_connections_per_instance = backend.value.max_connections_per_instance
      max_rate                     = backend.value.max_rate
      max_rate_per_endpoint        = backend.value.max_rate_per_endpoint
      max_rate_per_instance        = backend.value.max_rate_per_instance
      max_utilization              = backend.value.max_utilization

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

  dynamic "circuit_breakers" {
    for_each = each.value.circuit_breakers == null ? [] : [each.value.circuit_breakers]
    content {
      max_connections             = circuit_breakers.value.max_connections
      max_pending_requests        = circuit_breakers.value.max_pending_requests
      max_requests                = circuit_breakers.value.max_requests
      max_requests_per_connection = circuit_breakers.value.max_requests_per_connection
      max_retries                 = circuit_breakers.value.max_retries
    }
  }

  # consistent_hash {} # This field only applies if the load_balancing_scheme is set to INTERNAL_SELF_MANAGED.

  dynamic "custom_metrics" {
    for_each = each.value.custom_metrics_map
    content {
      dry_run = custom_metrics.value.dry_run
      name    = custom_metrics.value.name
    }
  }

  # failover_policy {} # For load balancers that have configurable failover: Internal passthrough Network Load Balancers and external passthrough Network Load Balancers.

  dynamic "iap" {
    for_each = each.value.iap == null ? [] : [each.value.iap]
    content {
      enabled              = iap.value.enabled
      oauth2_client_id     = iap.value.oauth2_client_id
      oauth2_client_secret = iap.value.oauth2_client_secret
    }
  }

  log_config {
    enable          = true
    optional_fields = each.value.log_config.optional_fields
    optional_mode   = each.value.log_config.optional_mode
    sample_rate     = 1
  }


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

      base_ejection_time {
        nanos   = outlier_detection.value.base_ejection_time.nanos
        seconds = outlier_detection.value.base_ejection_time.seconds
      }

      interval {
        nanos   = outlier_detection.value.interval.nanos
        seconds = outlier_detection.value.interval.seconds
      }
    }
  }

  dynamic "strong_session_affinity_cookie" {

    for_each = each.vale.session_affinity != "HTTP_COOKIE" ? [] : [each.value.strong_session_affinity_cookie]
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
