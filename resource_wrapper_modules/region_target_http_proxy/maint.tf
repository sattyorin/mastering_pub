variable "project_id" {
  type = string
}

variable "region_target_http_proxy" {
  type = object({
    name                        = string
    description                 = string
    http_keep_alive_timeout_sec = optional(number, 5)
    region                      = string
    url_map                     = string
  })
}

resource "google_compute_region_target_http_proxy" "region_target_http_proxy" {
  project                     = var.project_id
  name                        = var.region_target_http_proxy.name
  description                 = var.region_target_http_proxy.description
  http_keep_alive_timeout_sec = var.region_target_http_proxy.http_keep_alive_timeout_sec
  region                      = var.region_target_http_proxy.region
  url_map                     = var.region_target_http_proxy.url_map
}

resource "google_compute_region_target_http_proxy" "region_target_http_proxy" {
  project                     = var.project_id
  name                        = var.region_target_http_proxy.name
  description                 = var.region_target_http_proxy.description
  http_keep_alive_timeout_sec = var.region_target_http_proxy.http_keep_alive_timeout_sec
  region                      = var.region_target_http_proxy.region
  url_map                     = var.region_target_http_proxy.url_map
}

output "id" {
  value = google_compute_region_target_http_proxy.region_target_http_proxy.id
}
