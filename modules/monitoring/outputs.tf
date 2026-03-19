output "pagerduty_channel_id" {
  description = "PagerDuty notification channel ID"
  value       = google_monitoring_notification_channel.pagerduty.id
}

