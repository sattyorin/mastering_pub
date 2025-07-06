variable "project_id" {
  type = string
}

variable "register_psc_connections" {
  type = map(object({
    name   = string
    region = string
    psc_connection_map = map(object({
      forwarding_rule    = string
      ip_address         = string
      network            = string
      project_id         = string
      psc_connection_id  = string
      service_attachment = string
    }))
  }))
}

