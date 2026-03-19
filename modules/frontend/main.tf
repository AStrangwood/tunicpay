# Cloud Run services

resource "google_cloud_run_service" "api_backend" {
  name     = "${var.project_name}-api"
  location = var.region

  template {
    spec {
      container_concurrency = 80
      service_account_name  = var.api_backend_sa_email

      containers {
        image = var.api_backend_image

        resources {
          limits = {
            cpu    = "2"
            memory = "512Mi"
          }
        }

        env {
          name  = "DATABASE_HOST"
          value = var.db_private_ip
        }
        env {
          name  = "DATABASE_NAME"
          value = var.db_name
        }
        env {
          name  = "DATABASE_USER"
          value = var.db_user
        }
        env {
          name = "DATABASE_PASSWORD"
          value_from {
            secret_key_ref {
              name = var.db_password_secret_id
              key  = "latest"
            }
          }
        }

        env {
          name = "ONFIDO_API_KEY"
          value_from {
            secret_key_ref {
              name = var.onfido_secret_id
              key  = "latest"
            }
          }
        }

        env {
          name  = "GCS_BUCKET"
          value = var.documents_bucket_name
        }

        ports {
          container_port = 8080
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "100"
        "run.googleapis.com/client-name"          = "terraform"
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector_name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal"
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

resource "google_cloud_run_service" "web_ui" {
  name     = "${var.project_name}-web"
  location = var.region

  template {
    spec {
      service_account_name = var.web_ui_sa_email

      containers {
        image = var.web_ui_image

        resources {
          limits = {
            cpu    = "1"
            memory = "256Mi"
          }
        }

        env {
          name  = "API_URL"
          value = google_cloud_run_service.api_backend.status[0].url
        }
        env {
          name  = "DOCUMENT_BUCKET"
          value = var.documents_bucket_name
        }

        ports {
          container_port = 3000
        }
      }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"        = "50"
        "run.googleapis.com/client-name"          = "terraform"
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector_name
        "run.googleapis.com/vpc-access-egress"    = "private-ranges-only"
      }
    }
  }

  metadata {
    annotations = {
      "run.googleapis.com/ingress" = "internal-and-cloud-load-balancing"
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Web UI is customer-facing — allow unauthenticated access via load balancer
resource "google_cloud_run_service_iam_member" "web_ui_public" {
  service  = google_cloud_run_service.web_ui.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Web UI SA can invoke the API backend
resource "google_cloud_run_service_iam_member" "web_invoke_api" {
  service  = google_cloud_run_service.api_backend.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.web_ui_sa_email}"
}

