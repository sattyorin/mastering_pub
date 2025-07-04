variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "postgresql_instances" {
  type = map(object({
    name                 = string
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
  }))
}
