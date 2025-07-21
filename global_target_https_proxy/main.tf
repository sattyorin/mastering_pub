resource "google_compute_target_https_proxy" "global_target_https_proxy" {
  name                             = var.global_target_https_proxy.name
  description                      = var.global_target_https_proxy.description
  certificate_manager_certificates = null # certificate map を利用する
  certificate_map                  = var.global_target_https_proxy.certificate_map
  http_keep_alive_timeout_sec      = var.global_target_https_proxy.http_keep_alive_timeout_sec
  proxy_bind                       = false # 同じポートを使用する複数のサービスを利用する場合に true を設定 # INTERNAL_SELF_MANAGED 用
  quic_override                    = var.global_target_https_proxy.quic_override
  server_tls_policy                = var.global_target_https_proxy.server_tls_policy
  ssl_certificates                 = null # certificate map を利用する
  ssl_policy                       = var.global_target_https_proxy.ssl_policy
  tls_early_data                   = var.global_target_https_proxy.tls_early_data
  url_map                          = var.global_target_https_proxy.url_map
}
