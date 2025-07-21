variable "project_id" {
  type = string
}

variable "certificate_manager_global_managed_certificates" {
  type = map(object({
    name               = string
    description        = string
    labels             = map(string)
    scope              = string
    dns_authorizations = list(string)
    domains            = list(string)
    issuance_config    = optional(string)
  }))
}
