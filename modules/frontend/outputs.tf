output "web_ui_url" {
  description = "Web UI service URL"
  value       = google_cloud_run_service.web_ui.status[0].url
}

output "api_backend_url" {
  description = "API backend service URL"
  value       = google_cloud_run_service.api_backend.status[0].url
}

output "api_backend_name" {
  description = "API backend service name"
  value       = google_cloud_run_service.api_backend.name
}

