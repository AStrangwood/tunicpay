module "docuvault" {
  source = "../../modules/docuvault"

  project_id   = "docuvault-dev-385212"
  project_name = "docuvault"
  region       = "us-central1"
  zone         = "us-central1-a"
  environment  = "development"

  # Container images — pin to specific versions, never :latest
  api_backend_image = "gcr.io/docuvault-dev-385212/api-backend:v1.0.0"
  web_ui_image      = "gcr.io/docuvault-dev-385212/web-ui:v1.0.0"

  # Provided via CI environment variables (TF_VAR_*)
  pagerduty_integration_key = var.pagerduty_integration_key
}