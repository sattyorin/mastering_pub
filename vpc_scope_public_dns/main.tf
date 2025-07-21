module "vpc_scope_public_dns_managed_zone" {
  source = "../../resource_wrapper_modules/vpc_scope_public_dns_managed_zone"

  project_id = var.project_id
  network_id = var.network_id
  vpc_scope_public_dns_managed_zone = {
    for key, value in var.vpc_scope_public_dns : key => {
      description   = value.description
      dns_name      = value.dns_name
      labels        = value.labels
      name          = value.name
      dnssec_config = value.dnssec_config
  } }
}

module "simple_dns_record_set" {
  source = "../../resource_wrapper_modules/simple_dns_record_set"

  project_id = var.project_id
  simple_dns_record_set = merge([
    for zone_key, zone_value in var.vpc_scope_public_dns : {
      for recode_key, recode_value in zone_value.dns_record_set : "${zone_key}_${recode_key}" => {
        managed_zone = module.vpc_scope_private_dns_managed_zone.ids["${zone_key}"]
        name         = recode_value.name
        rrdatas      = recode_value.rrdatas
        ttl          = recode_value.ttl
        type         = recode_value.type
        health_check = recode_value.health_check
    } }
  ]...)

}
