variable "global_target_https_proxy" {
  type = object({
    name                        = string
    description                 = string
    certificate_map             = string
    http_keep_alive_timeout_sec = number
    quic_override               = optional(string)
    server_tls_policy           = optional(string)
    ssl_policy                  = optional(string)
    tls_early_data              = optional(bool)
    url_map                     = string
  })
}
