resource "google_cloudfunctions_function" "" {
  for_each = var.cloudfunctions_function

  available_memory_mb           = each.value.available_memory_mb
  build_environment_variables   = each.value.build_environment_variables
  build_service_account         = each.value.build_service_account
  build_worker_pool             = each.value.build_worker_pool
  description                   = each.value.description
  docker_registry               = each.value.docker_registry
  docker_repository             = each.value.docker_repository
  entry_point                   = each.value.entry_point
  environment_variables         = each.value.environment_variables
  https_trigger_security_level  = each.value.https_trigger_security_level
  https_trigger_url             = each.value.https_trigger_url
  ingress_settings              = each.value.ingress_settings
  kms_key_name                  = each.value.kms_key_name
  labels                        = each.value.labels
  max_instances                 = each.value.max_instances
  min_instances                 = each.value.min_instances
  name                          = each.value.name
  project                       = each.value.project
  region                        = each.value.region
  runtime                       = each.value.runtime
  service_account_email         = each.value.service_account_email
  source_archive_bucket         = each.value.source_archive_bucket
  source_archive_object         = each.value.source_archive_object
  timeout                       = each.value.timeout
  trigger_http                  = each.value.trigger_http
  vpc_connector                 = each.value.vpc_connector
  vpc_connector_egress_settings = each.value.vpc_connector_egress_settings

  dynamic "event_trigger" {
    for_each = each.value.event_trigger == null ? [] : [each.value.event_trigger]
    content {
      event_type = event_trigger.value.event_type
      resource   = event_trigger.value.resource
      dynamic "failure_policy" {
        for_each = event_trigger.value.failure_policy == null ? [] : [event_trigger.value.failure_policy]
        content {
          retry = failure_policy.value.retry
        }
      }
    }
  }
  dynamic "secret_environment_variables" {
    for_each = each.value.secret_environment_variables_map
    content {
      key        = secret_environment_variables.value.key
      project_id = secret_environment_variables.value.project_id
      secret     = secret_environment_variables.value.secret
      version    = secret_environment_variables.value.version
    }
  }
  dynamic "secret_volumes" {
    for_each = each.value.secret_volumes_map
    content {
      mount_path = secret_volumes.value.mount_path
      project_id = secret_volumes.value.project_id
      secret     = secret_volumes.value.secret
      dynamic "versions" {
        for_each = secret_volumes.value.versions_map
        content {
          path    = versions.value.path
          version = versions.value.version
        }
      }
    }
  }
  dynamic "source_repository" {
    for_each = each.value.source_repository == null ? [] : [each.value.source_repository]
    content {
      url = source_repository.value.url
    }
  }
}
