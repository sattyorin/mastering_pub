variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "managed_certificates_with_dns_authorization" {
  type = map(object({
    domain_display_name = string
    domain              = string
    labels              = map(string)
  }))
}
