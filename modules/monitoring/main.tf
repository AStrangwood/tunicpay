# Monitoring and logging

# ── PagerDuty notification channel ───────────────────────────
resource "google_monitoring_notification_channel" "pagerduty" {
  display_name = "PagerDuty - DocuVault"
  type         = "pagerduty"

  labels = {
    service_key = var.pagerduty_integration_key
  }
}

# ── Alerts ───────────────────────────────────────────────────
resource "google_monitoring_alert_policy" "cpu_alert" {
  display_name = "${var.project_name} ${var.environment} - High CPU - Cloud Run"
  combiner     = "OR"

  conditions {
    display_name = "CPU utilization above 80%"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container/cpu/utilizations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** Cloud Run (all revisions)
      **Environment:** ${var.environment}
      **Threshold:** P99 CPU > 80% for 5 minutes

      **Steps:**
      1. Check Cloud Run metrics in console: https://console.cloud.google.com/run?project=${var.project_id}
      2. Look at recent deployments — did a new revision just roll out?
      3. Check request volume — is this a traffic spike or a code regression?
      4. If a bad deploy, roll back to previous revision
      5. If traffic spike, check if maxScale needs increasing
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "warning"
  }
}

resource "google_monitoring_alert_policy" "memory_alert" {
  display_name = "${var.project_name} ${var.environment} - High Memory - Cloud Run"
  combiner     = "OR"

  conditions {
    display_name = "Memory utilization above 85%"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/container/memory/utilizations\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** Cloud Run (all revisions)
      **Environment:** ${var.environment}
      **Threshold:** P99 Memory > 85% for 5 minutes

      **Steps:**
      1. Check which revision is affected in Cloud Run console
      2. Check for memory leaks — is usage climbing over time or spiking suddenly?
      3. If sudden spike, correlate with recent deploys or traffic changes
      4. If gradual climb, likely a memory leak — roll back and investigate
      5. If legitimate load, increase memory limit in services.tf
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "warning"
  }
}

resource "google_monitoring_alert_policy" "error_rate_alert" {
  display_name = "${var.project_name} ${var.environment} - High 5xx Rate - Cloud Run"
  combiner     = "OR"

  conditions {
    display_name = "5xx error rate above 5%"

    condition_threshold {
      filter          = "resource.type = \"cloud_run_revision\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      comparison      = "COMPARISON_GT"
      threshold_value = 5
      duration        = "60s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** Cloud Run (all revisions)
      **Environment:** ${var.environment}
      **Threshold:** 5xx error rate > 5% for 1 minute

      **Steps:**
      1. Check Cloud Run logs for error details: https://console.cloud.google.com/logs?project=${var.project_id}
      2. Filter by severity=ERROR and the affected service
      3. Is it one service or both? (api-backend errors will cascade to web-ui)
      4. Check Cloud SQL — is the database reachable? Connection pool exhausted?
      5. Check external dependencies — is Onfido API responding?
      6. If caused by a bad deploy, roll back to previous revision
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "critical"
  }
}

resource "google_monitoring_alert_policy" "sql_connection_alert" {
  display_name = "${var.project_name} ${var.environment} - Cloud SQL Connection Failure"
  combiner     = "OR"

  conditions {
    display_name = "Failed connections above 0"

    condition_threshold {
      filter          = "resource.type = \"cloudsql_database\" AND metric.type = \"cloudsql.googleapis.com/database/network/connections\""
      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** Cloud SQL (${var.project_name}-db)
      **Environment:** ${var.environment}
      **Threshold:** Active connections dropped to 0 for 5 minutes

      **Steps:**
      1. Check Cloud SQL instance status: https://console.cloud.google.com/sql/instances?project=${var.project_id}
      2. Is the instance running? Check for maintenance windows or failovers
      3. Check VPC connectivity — has a network/firewall change broken private access?
      4. Check Cloud Run logs — are the services failing to connect?
      5. If the instance is down, check for storage/memory limits
      6. Escalate to database team if instance won't recover
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "critical"
  }
}

# ── Storage bucket alerts ────────────────────────────────────
resource "google_monitoring_alert_policy" "storage_permission_denied" {
  display_name = "${var.project_name} ${var.environment} - Storage Permission Denied"
  combiner     = "OR"

  conditions {
    display_name = "Permission denied errors on document bucket"

    condition_threshold {
      filter          = "resource.type = \"gcs_bucket\" AND resource.labels.bucket_name = \"${var.documents_bucket_name}\" AND metric.type = \"storage.googleapis.com/api/request_count\" AND metric.labels.response_code = \"PERMISSION_DENIED\""
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** GCS (${var.documents_bucket_name})
      **Environment:** ${var.environment}
      **Threshold:** > 10 PERMISSION_DENIED responses in 5 minutes

      This could indicate:
      - A misconfigured service trying to access the bucket
      - An unauthorized access attempt
      - IAM permissions changed unexpectedly

      **Steps:**
      1. Check Cloud Audit logs for the bucket: https://console.cloud.google.com/logs?project=${var.project_id}
      2. Filter by `resource.type="gcs_bucket"` and `status.code=7`
      3. Identify the caller — is it a known service account or something unexpected?
      4. If unexpected, investigate as a potential security incident
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "critical"
  }
}

resource "google_monitoring_alert_policy" "storage_object_deletes" {
  display_name = "${var.project_name} ${var.environment} - Unusual Document Deletions"
  combiner     = "OR"

  conditions {
    display_name = "High rate of object deletions on document bucket"

    condition_threshold {
      filter          = "resource.type = \"gcs_bucket\" AND resource.labels.bucket_name = \"${var.documents_bucket_name}\" AND metric.type = \"storage.googleapis.com/api/request_count\" AND metric.labels.method = \"DeleteObject\""
      comparison      = "COMPARISON_GT"
      threshold_value = 50
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }

      trigger {
        count = 1
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = <<-EOT
      **Service:** GCS (${var.documents_bucket_name})
      **Environment:** ${var.environment}
      **Threshold:** > 50 object deletions in 5 minutes

      Bulk deletion of customer documents is unusual and could indicate:
      - A bug in the application
      - A compromised service account
      - An accidental cleanup script running against production

      **Steps:**
      1. Check who is deleting: Cloud Audit logs filtered by `methodName="storage.objects.delete"`
      2. Is the caller the API backend SA or something else?
      3. If unexpected, revoke the caller's access immediately
      4. Versioning is enabled — deleted objects can be recovered from non-current versions
    EOT
    mime_type = "text/markdown"
  }

  user_labels = {
    environment = var.environment
    team        = "platform"
    severity    = "critical"
  }
}

# ── Audit log sink ───────────────────────────────────────────
resource "google_storage_bucket" "log_sink" {
  name          = "${var.project_id}-audit-logs"
  location      = "US"
  force_destroy = false

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Retain audit logs for 365 days (compliance requirement)
  retention_policy {
    is_locked        = true
    retention_period = 31536000
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  labels = {
    purpose             = "audit-logs"
    data-classification = "audit"
  }
}

resource "google_logging_project_sink" "audit_sink" {
  name        = "audit-log-sink"
  destination = "storage.googleapis.com/${google_storage_bucket.log_sink.name}"
  filter      = "logName:\"logs/cloudaudit.googleapis.com\" OR logName:\"logs/data_access\""

  unique_writer_identity = true
}

resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = google_storage_bucket.log_sink.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.audit_sink.writer_identity
}
