variable "project_id" {
  type = string

}
variable "network_id" {
  type = string
}

variable "vpc_scope_public_dns_managed_zone" {
  type = map(object({
    description = string
    dns_name    = string
    labels      = map(string)
    name        = string
    dnssec_config = object({
      kind          = optional(string)
      non_existence = optional(string)
      state         = string
      default_key_specs_map = optional(map(object({
        algorithm  = string
        key_length = number
        key_type   = string
        kind       = string
      })), {})
    })
  }))
}


