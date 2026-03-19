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

variable "network_id" {
  description = "VPC network self-link for Cloud SQL private networking"
  type        = string
}

variable "api_backend_sa_email" {
  description = "API backend service account email for resource-scoped IAM"
  type        = string
}



