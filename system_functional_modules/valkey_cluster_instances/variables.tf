variable "project_id" {
  type = string
}

variable "network_id" {
  type = string
}

variable "valkey_cluster_instances" {
  type = map(object({
    instance_id = string
    labels      = map(string)
  }))
}
