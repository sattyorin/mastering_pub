resource "google_dns_managed_zone" "vpc_scope_public_dns_managed_zone" {
  for_each = var.vpc_scope_public_dns_managed_zone

  description   = each.value.description
  dns_name      = each.value.dns_name
  force_destroy = true # リソースの存在がサービスの有効化を意味する
  labels        = each.value.labels
  name          = each.value.name
  project       = var.project_id
  visibility    = "public"

  cloud_logging_config {
    enable_logging = true
  }

  dnssec_config {
    kind          = dnssec_config.value.kind
    non_existence = dnssec_config.value.non_existence
    state         = dnssec_config.value.state
    dynamic "default_key_specs" {
      for_each = dnssec_config.value.default_key_specs_map
      content {
        algorithm  = default_key_specs.value.algorithm
        key_length = default_key_specs.value.key_length
        key_type   = default_key_specs.value.key_type
        kind       = default_key_specs.value.kind
      }
    }
  }

  # forwarding_config {} # 外部 DNS ゾーンでは使用しない

  # peering_config {} # 外部 DNS ゾーンでは使用しない

  private_visibility_config {
    # gke_clusters {} # VPC スコープのモジュールであるためここでは対象外
    networks {
      network_url = var.network_id
    }
  }

}
