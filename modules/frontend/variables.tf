variable "project_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "api_backend_sa_email" {
  description = "API backend service account email"
  type        = string
}

variable "web_ui_sa_email" {
  description = "Web UI service account email"
  type        = string
}

variable "db_private_ip" {
  description = "Cloud SQL private IP address"
  type        = string
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_user" {
  description = "Database application user"
  type        = string
}

variable "db_password_secret_id" {
  description = "Secret Manager secret ID for database password"
  type        = string
}

variable "onfido_secret_id" {
  description = "Secret Manager secret ID for Onfido API key"
  type        = string
}

variable "documents_bucket_name" {
  description = "Customer documents bucket name"
  type        = string
}

variable "api_backend_image" {
  description = "Container image for the API backend (pin to a specific version or digest, never use :latest)"
  type        = string
}

variable "web_ui_image" {
  description = "Container image for the web UI (pin to a specific version or digest, never use :latest)"
  type        = string
}

variable "vpc_connector_name" {
  description = "VPC Access Connector name for private network access"
  type        = string
}

