variable "project_id" {
  type = string
}

variable "monitoring_alert_policies_with_builder" {
  description = "Map of monitoring alert policies with builder"
  type = map(object({
    combiner              = string
    display_name          = string
    enabled               = bool
    notification_channels = list(string)
    severity              = string
    user_labels           = map(string)

    alert_strategy = object({
      auto_close = string
    })

    conditions_map = map(object({
      display_name = string

      condition_matched_log = optional(object({
        filter           = string
        label_extractors = map(string)
      }), {})

      condition_threshold = optional(object({
        comparison              = string
        denominator_filter      = optional(string)
        duration                = string
        evaluation_missing_data = string
        filter                  = string
        threshold_value         = number

        aggregations_map = optional(map(object({
          alignment_period     = string
          cross_series_reducer = string
          group_by_fields      = list(string)
          per_series_aligner   = string
        })))

        denominator_aggregations_map = optional(map(object({
          alignment_period     = string
          cross_series_reducer = string
          group_by_fields      = list(string)
          per_series_aligner   = string
        })))

        trigger = optional(object({
          count   = number
          percent = number
        }))

      }))
    }))

    documentation = optional(object({
      content   = string
      mime_type = string
      subject   = optional(string)
      links_map = map(object({
        display_name = string
        url          = string
      }))
    }))
  }))
}


