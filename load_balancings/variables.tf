variable "project_id" {
  type = string
}
variable "resource_prefix" {
  type = string
}
variable "network_id" {
  type = string
}

variable "domain" {
  type = string
}

variable "domain_display_name" {
  type = string
}

variable "external_loadbalancing_addresses" {
  type = map(object({
    name             = string
    address          = string
    prefix_length    = optional(number)
    source_ip_ranges = optional(list(string))
  }))
}

variable "url_map" {
  type = object({
    url_map_default_service = string
    host_rule_map = map(object({
      name            = string
      hosts           = list(string)
      default_service = string
      path_rule_map = map(object({
        paths   = list(string)
        service = string
      }))
    }))
  })
}

variable "backend_services" {
  type = map(object({
    name        = string
    description = string
    backend_map = map(object({
      zone_suffix                 = string
      network_endpoint_group_name = string
    }))
  }))
}
