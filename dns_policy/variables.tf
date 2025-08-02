variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "enable_inbound_forwarding" {
  type = bool
}

variable "target_name_servers_map" {
  type = map(object({
    forwarding_path = string
    ipv4_address    = string
  }))
  default = null
}

variable "networks_url_list" {
  type = list(string)
}
