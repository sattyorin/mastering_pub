variable "project_id" {
  type = string
}

variable "certificate_manager_certificate_map_entries" {
  type = map(object({
    name         = string
    certificates = list(string)
    description  = string
    hostname     = string
    labels       = map(string)
    map          = string
    matcher      = string
  }))
}
