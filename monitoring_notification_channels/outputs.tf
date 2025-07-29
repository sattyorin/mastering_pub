output "ids" {
  value = { for key, value in google_monitoring_notification_channel.notification_channels : key => value.id }
}
