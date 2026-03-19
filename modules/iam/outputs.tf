output "api_backend_sa_email" {
  description = "API backend service account email"
  value       = google_service_account.api_backend.email
}

output "web_ui_sa_email" {
  description = "Web UI service account email"
  value       = google_service_account.web_ui.email
}

