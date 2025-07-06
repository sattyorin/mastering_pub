variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "subnet_cidr_range" {
  type = string
}

variable "valkey_cluster_instances" {
  type = map(object({
    instance_id       = string
    labels            = map(string)
    address_discovery = string
    address_primary   = string
    dns_display_name  = string
    dns_name          = string
    dns_a_record_name = string
  }))
}
