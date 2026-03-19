
variable "pagerduty_integration_key" {
  description = "PagerDuty integration key — provided via TF_VAR_pagerduty_integration_key in CI"
  type        = string
  sensitive   = true
}

