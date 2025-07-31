variable "project_id" {
  type = string
}

variable "description" {
  type = string
}

variable "global_policy_evaluation_mode" {
  type = string
}

variable "admission_whitelist_patterns_map" {
  type = map(object({
    name_pattern = string
  }))
}

variable "cluster_admission_rules_map" {
  type = map(object({
    cluster                 = string
    enforcement_mode        = string
    evaluation_mode         = string
    require_attestations_by = list(string)
  }))
}

variable "default_admission_rule" {
  type = optional(object({
    enforcement_mode        = string
    evaluation_mode         = string
    require_attestations_by = list(string)
  }), null)
}

resource "google_binary_authorization_policy" "binary_authorization_policy" {

  project                       = var.project_id
  description                   = var.description
  global_policy_evaluation_mode = var.global_policy_evaluation_mode

  dynamic "admission_whitelist_patterns" {
    for_each = var.admission_whitelist_patterns_map
    content {
      name_pattern = admission_whitelist_patterns.value.name_pattern
    }
  }

  dynamic "cluster_admission_rules" {
    for_each = var.cluster_admission_rules_map
    content {
      cluster                 = cluster_admission_rules.value.cluster
      enforcement_mode        = cluster_admission_rules.value.enforcement_mode
      evaluation_mode         = cluster_admission_rules.value.evaluation_mode
      require_attestations_by = cluster_admission_rules.value.require_attestations_by
    }
  }

  dynamic "default_admission_rule" {
    for_each = var.default_admission_rule == null ? [] : [var.default_admission_rule]
    content {
      enforcement_mode        = default_admission_rule.value.enforcement_mode
      evaluation_mode         = default_admission_rule.value.evaluation_mode
      require_attestations_by = default_admission_rule.value.require_attestations_by
    }
  }

}
