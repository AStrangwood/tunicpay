variable "project_name" {
  description = "Prefix for resource names"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name (development, production)"
  type        = string
}

variable "pagerduty_integration_key" {
  description = "PagerDuty service integration key for alert routing"
  type        = string
  sensitive   = true
}

variable "documents_bucket_name" {
  description = "Customer documents bucket name for storage alerts"
  type        = string
}

