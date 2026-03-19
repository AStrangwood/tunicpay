output "db_connection_name" {
  description = "Cloud SQL connection name for Auth Proxy"
  value       = google_sql_database_instance.main.connection_name
}

output "db_private_ip" {
  description = "Cloud SQL private IP address"
  value       = google_sql_database_instance.main.private_ip_address
}

output "db_name" {
  description = "Database name"
  value       = google_sql_database.app.name
}

output "db_user" {
  description = "Database application user"
  value       = google_sql_user.app.name
}

output "db_password_secret_id" {
  description = "Secret Manager secret ID for database password"
  value       = google_secret_manager_secret.db_password.secret_id
}

output "onfido_secret_id" {
  description = "Secret Manager secret ID for Onfido API key"
  value       = google_secret_manager_secret.onfido_api_key.secret_id
}

output "documents_bucket_name" {
  description = "Customer documents bucket name"
  value       = google_storage_bucket.documents.name
}

output "documents_bucket_url" {
  description = "Customer documents bucket URL"
  value       = google_storage_bucket.documents.url
}

