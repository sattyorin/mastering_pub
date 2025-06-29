variable "project_id" {
  type = string
}

variable "http_health_checks" {
  type = map(object({
    name                = string
    description         = string
    check_interval_sec  = number
    healthy_threshold   = number
    port                = number
    request_path        = string
    timeout_sec         = number
    unhealthy_threshold = number
  }))
}

resource "google_compute_http_health_check" "http_health_checks" {
  for_each = var.http_health_checks

  project             = var.project_id
  name                = each.value.name
  description         = each.value.description
  check_interval_sec  = each.value.check_interval_sec
  healthy_threshold   = each.value.healthy_threshold
  host                = null
  port                = each.value.port
  request_path        = each.value.request_path
  timeout_sec         = each.value.timeout_sec
  unhealthy_threshold = each.value.unhealthy_threshold
}

output "ids" {
  value = { for key, value in resource.google_compute_http_health_check.http_health_checks : key => value.id }
}
