variable "project_id" {
  type = string
}

variable "certificate_manager_certificate_maps" {
  type = map(object({
    name        = string
    description = string
    labels      = map(string)
  }))
}
