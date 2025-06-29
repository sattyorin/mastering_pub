variable "project_id" {
  type = string
}

variable "compute_global_addresses" {
  type = map(object({
    name          = string
    network       = string
    description   = string
    purpose       = string # null or "VPC_PEERING" or "PRIVATE_SERVICE_CONNECT" (beta)
    address_type  = string
    address       = string
    prefix_length = number
    labels        = optional(map(string), {})
  }))
}

resource "google_compute_global_addresses" "compute_global_addresses" {
  for_each = var.compute_global_addresses

  project       = var.project_id
  name          = each.value.name
  network       = each.value.network
  description   = each.value.description
  purpose       = each.value.purpose
  address_type  = each.value.address_type
  ip_version    = "IPV4"
  address       = each.value.address
  prefix_length = each.value.prefix_length
  labels        = each.value.labels
}
