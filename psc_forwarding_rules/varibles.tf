variable "project_id" {
  type = string
}

variable "psc_forwarding_rules" {
  type = map(object({
    name                = string
    description         = string
    labels              = map(string)
    ip_address          = string
    ip_protocol         = string
    ports               = list(string)
    recreate_closed_psc = bool
    region              = string
    service_label       = string
    source_ip_ranges    = list(string)
    subnetwork          = string
    target              = string
    service_directory_registrations = optional(object({
      namespace = string
      service   = string
    }), null)
  }))
}
