# DocuVault Platform Infrastructure
# Orchestrator module — calls sub-modules and wires outputs between them

terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.46"
    }
  }
}

module "network" {
  source = "../network"

  project_name = var.project_name
  region       = var.region
}

module "iam" {
  source = "../iam"

  project_name = var.project_name
  project_id   = var.project_id
}

module "backend" {
  source = "../backend"

  project_name         = var.project_name
  project_id           = var.project_id
  region               = var.region
  network_id           = module.network.network_id
  api_backend_sa_email = module.iam.api_backend_sa_email
}

module "frontend" {
  source = "../frontend"

  project_name          = var.project_name
  project_id            = var.project_id
  region                = var.region
  api_backend_sa_email  = module.iam.api_backend_sa_email
  web_ui_sa_email       = module.iam.web_ui_sa_email
  db_private_ip         = module.backend.db_private_ip
  db_name               = module.backend.db_name
  db_user               = module.backend.db_user
  db_password_secret_id = module.backend.db_password_secret_id
  onfido_secret_id      = module.backend.onfido_secret_id
  documents_bucket_name = module.backend.documents_bucket_name
  api_backend_image     = var.api_backend_image
  web_ui_image          = var.web_ui_image
  vpc_connector_name    = module.network.vpc_connector_name
}

module "monitoring" {
  source = "../monitoring"

  project_name              = var.project_name
  project_id                = var.project_id
  environment               = var.environment
  pagerduty_integration_key = var.pagerduty_integration_key
  documents_bucket_name     = module.backend.documents_bucket_name
}
