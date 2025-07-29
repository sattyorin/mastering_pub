resource "google_monitoring_alert_policy" "monitoring_alert_policies_with_builder" {
  for_each = var.monitoring_alert_policies_with_builder

  project               = var.project_id
  combiner              = each.value.combiner
  display_name          = each.value.display_name
  enabled               = each.value.enabled
  notification_channels = each.value.notification_channels
  severity              = each.value.severity
  user_labels           = each.value.user_labels

  alert_strategy {
    auto_close           = alert_strategy.value.auto_close
    notification_prompts = ["OPENED", "CLOSED"]

    # notification_channel_strategy {} # 再通知は想定しない
    # notification_rate_limit {} # 再通知は想定しない

  }

  dynamic "conditions" {
    for_each = each.value.conditions_map
    content {
      display_name = conditions.value.display_name

      # condition_absent {} # もし使うなら別途 Module を作成する

      dynamic "condition_matched_log" {
        for_each = conditions.value.condition_matched_log == null ? [] : [conditions.value.condition_matched_log]
        content {
          filter           = condition_matched_log.value.filter
          label_extractors = condition_matched_log.value.label_extractors
        }
      }

      # condition_monitoring_query_language {} # MQL は廃止予定のため使用しない
      # condition_prometheus_query_language {} # ここでの対象ば Builder であるため使用しない
      # condition_sql {} # ここでの対象は Metrics であるため使用しない

      dynamic "condition_threshold" {
        for_each = conditions.value.condition_threshold == null ? [] : [conditions.value.condition_threshold]
        content {
          comparison              = condition_threshold.value.comparison
          denominator_filter      = condition_threshold.value.denominator_filter
          duration                = condition_threshold.value.duration
          evaluation_missing_data = condition_threshold.value.evaluation_missing_data
          filter                  = condition_threshold.value.filter
          threshold_value         = condition_threshold.value.threshold_value

          dynamic "aggregations" {
            for_each = condition_threshold.value.aggregations_map
            content {
              alignment_period     = aggregations.value.alignment_period
              cross_series_reducer = aggregations.value.cross_series_reducer
              group_by_fields      = aggregations.value.group_by_fields
              per_series_aligner   = aggregations.value.per_series_aligner
            }
          }

          dynamic "denominator_aggregations" {
            for_each = condition_threshold.value.denominator_aggregations_map
            content {
              alignment_period     = denominator_aggregations.value.alignment_period
              cross_series_reducer = denominator_aggregations.value.cross_series_reducer
              group_by_fields      = denominator_aggregations.value.group_by_fields
              per_series_aligner   = denominator_aggregations.value.per_series_aligner
            }
          }

          # forecast_options {} # ここでは使用しない

          dynamic "trigger" {
            for_each = condition_threshold.value.trigger == null ? [] : [condition_threshold.value.trigger]
            content {
              count   = trigger.value.count
              percent = trigger.value.percent
            }
          }

        }
      }
    }
  }

  dynamic "documentation" {
    for_each = each.value.documentation == null ? [] : [each.value.documentation]
    content {
      content   = documentation.value.content
      mime_type = documentation.value.mime_type
      subject   = documentation.value.subject
      dynamic "links" {
        for_each = documentation.value.links_map
        content {
          display_name = links.value.display_name
          url          = links.value.url
        }
      }
    }
  }

}
