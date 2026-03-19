# Useful endpoints for development

output "web_ui_url" {
  value = module.frontend.web_ui_url
}

output "api_backend_url" {
  value = module.frontend.api_backend_url
}

output "database_connection_name" {
  value = module.backend.db_connection_name
}

output "document_bucket" {
  value = module.backend.documents_bucket_url
}

output "api_backend_service_account" {
  value = module.iam.api_backend_sa_email
}

output "web_ui_service_account" {
  value = module.iam.web_ui_sa_email
}
