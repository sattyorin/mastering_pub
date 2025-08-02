output "ids" {
  value = { for key, value in resource.google_pubsub_topic.simple_pubsub_topics : key => value.id }
}
