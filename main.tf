module "load_balancing" {
  source = "system_functional_modules/load_balancings"

  project_id                       = var.project_id
  resource_prefix                  = local.resource_prefix
  network_id                       = local.network_id
  external_loadbalancing_addresses = var.external_loadbalancing_addresses

  backend_services = {
    "hoge" = {
      name        = "hoge"
      description = "hoge"
      backend_map = {
        "zone-a" = {
          zone_suffix                 = "a"
          network_endpoint_group_name = "hoge-neg-a"
        }
        "zone-b" = {
          zone_suffix                 = "b"
          network_endpoint_group_name = "hoge-neg-b"
        }
      }
    }

  }
  url_map = {
    url_map_default_service = module.load_balancing.backend_service_ids["hoge"]
    host_rule_map = {
      "example.com" = {
        name            = "example-com"
        hosts           = ["example.com"]
        default_service = module.load_balancing.backend_service_ids["hoge"]
        path_rule_map = {
          "api" = {
            paths   = ["/api/*"]
            service = module.load_balancing.backend_service_ids["hoge"]
          }
        }
      }
    }
  }

}
