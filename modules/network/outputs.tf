output "network_id" {
  description = "VPC network self-link for Cloud SQL private networking"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}

output "subnet_id" {
  description = "Subnet self-link"
  value       = google_compute_subnetwork.main.id
}

output "vpc_connector_name" {
  description = "VPC Access Connector name for Cloud Run"
  value       = google_vpc_access_connector.main.name
}

