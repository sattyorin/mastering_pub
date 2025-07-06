variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "postgresql_instances" {
  type = map(object({
    subnet_cidr_range    = string
    address              = string
    instance_name        = string
    master_instance_name = optional(string, null)
    replica_names        = optional(list(string))
    root_password        = string
    settings = object({
      activation_policy = string
      disk_size         = number
      edition           = string
      tier              = string
      psa_name          = string
    })
    dns_name          = string
    dns_display_name  = string
    dns_a_record_name = string
  }))
}
