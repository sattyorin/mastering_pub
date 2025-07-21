variable "project_id" {
  type = string
}

variable "certificate_manager_global_dns_authorizations" {
  type = map(object({
    name        = string
    description = string
    domain      = string
    labels      = map(string)
  }))
}

