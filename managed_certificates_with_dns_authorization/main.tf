module "dns_authorizations" {
  source     = "../../resource_wrapper_modules/certificate_manager_global_dns_authorizations"
  project_id = var.project_id
  certificate_manager_global_dns_authorizations = {
    for key, value in var.managed_certificates_with_dns_authorization : key => {
      name        = value.domain_display_name
      description = "For managed certificate with DNS authorization for ${value.domain}"
      domain      = value.domain
      labels      = value.labels
    }
  }
}

module "dns" {
  source     = "../../system_functional_modules/vpc_scope_public_dns"
  project_id = var.project_id
  network_id = var.network_id
  vpc_scope_public_dns = {
    for key, value in var.managed_certificates_with_dns_authorization : key => {
      name        = value.domain_display_name
      description = "For managed certificate with DNS authorization for ${value.domain}"
      dns_name    = value.domain
      labels      = value.labels
      dnssec_config = {
        non_existence = "nsec3"
        state         = "off"
      }

      dns_record_set = {
        name         = module.dns_authorizations.dns_resource_records[key][0].name
        ttl          = 300
        type         = module.dns_authorizations.dns_resource_records[key][0].type
        health_check = null
        rrdatas = [
          module.dns_authorizations.dns_resource_records[key][0].data
        ]
      }
    }
  }
}

module "certificates" {
  source     = "../../resource_wrapper_modules/certificate_manager_global_managed_certificates"
  project_id = var.project_id
  certificate_manager_global_managed_certificates = {
    for key, value in var.managed_certificates_with_dns_authorization : key => {
      name               = value.domain_display_name
      description        = "For managed certificate with DNS authorization for ${value.domain}"
      labels             = value.labels
      scope              = "DEFAULT"
      dns_authorizations = [module.dns_authorizations.certificate_manager_global_dns_authorizations.ids[key]]
      domains            = [value.domain]
      issuance_config    = null # TODO(sara): 必要かを確認する
    }
  }
}

module "certificate_maps" {
  source     = "../../resource_wrapper_modules/certificate_manager_certificate_maps"
  project_id = var.project_id
  certificate_manager_certificate_maps = {
    for key, value in var.managed_certificates_with_dns_authorization : key => {
      name        = "${value.domain_display_name}-map"
      description = "For managed certificate with DNS authorization for ${value.domain}"
      labels      = value.labels
    }
  }
}

module "certificate_map_entries" {
  source     = "../../resource_wrapper_modules/certificate_manager_certificate_map_entries"
  project_id = var.project_id
  certificate_manager_certificate_map_entries = {
    name         = "${value.domain_display_name}-map-entry"
    certificates = [module.certificates.certificate_manager_global_managed_certificates.ids[key]]
    description  = "For managed certificate with DNS authorization for ${value.domain}"
    hostname     = value.domain
    labels       = value.labels
    map          = module.certificate_maps.certificate_manager_certificate_maps.ids[key]
    matcher      = null # プライマリ証明書は使用しない
  }
}

