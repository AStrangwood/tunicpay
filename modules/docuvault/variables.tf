variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Prefix for resource names"
  type        = string
  default     = "docuvault"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
  default     = "production"
}


variable "pagerduty_integration_key" {
  description = "PagerDuty service integration key for alert routing"
  type        = string
  sensitive   = true
}

variable "api_backend_image" {
  description = "Container image for the API backend — must be a specific version or digest, not :latest"
  type        = string
}

variable "web_ui_image" {
  description = "Container image for the web UI — must be a specific version or digest, not :latest"
  type        = string
}

