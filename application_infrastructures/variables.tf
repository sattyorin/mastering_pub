variable "project_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "hub_project_id" {
  type = string
}

variable "hub_network" {
  type = string
}

variable "network_id" {
  type = string
}

variable "cloud_sql_address" {
  type = string
}

variable "cloud_sql_prefix_length" {
  type = number
}

variable "memorystore_redis_address" {
  type = string
}

variable "memorystore_redis_prefix_length" {
  type = number
}

variable "primary_dmz" {
  type = object({
    subnet_ip_cidr_range  = string
    pod_ip_cidr_range     = string
    service_ip_cidr_range = string
  })
}

variable "primary_trust" {
  type = object({
    subnet_ip_cidr_range  = string
    pod_ip_cidr_range     = string
    service_ip_cidr_range = string
    gateway_address       = string
  })
}

variable "master_ipv4_cidr_block" {
  type = string
}

variable "gateway_ip_cidr_range" {
  type = string
}

variable "management_server_ip_cidr_range" {
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
