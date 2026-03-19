# Service accounts and project-level IAM bindings

resource "google_service_account" "api_backend" {
  account_id   = "${var.project_name}-api-sa"
  display_name = "API Backend Service Account"
  description  = "Service account for DocuVault API backend"
}

resource "google_service_account" "web_ui" {
  account_id   = "${var.project_name}-web-sa"
  display_name = "Web UI Service Account"
  description  = "Service account for DocuVault web UI"
}

# API backend — project-level Cloud SQL client access
resource "google_project_iam_member" "api_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.api_backend.email}"
}

