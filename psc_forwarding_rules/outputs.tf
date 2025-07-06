output "ids" {
  value = {
    for key, value in resource.google_compute_forwarding_rule.psc_forwarding_rules : key => value.id
  }
}

output "psc_connection_ids" {
  value = {
    for key, value in resource.google_compute_forwarding_rule.psc_forwarding_rules : key => value.id
  }
}
