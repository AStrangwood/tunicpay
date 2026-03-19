# Network configuration

resource "google_compute_network" "main" {
  name                    = "${var.project_name}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "main" {
  name          = "${var.project_name}-subnet"
  network       = google_compute_network.main.id
  ip_cidr_range = "10.0.0.0/24"
  region        = var.region

  private_ip_google_access = true
}

# Allow health check probes from GCP load balancers
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${var.project_name}-allow-health-checks"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["cloud-run"]
  description   = "Allow GCP health check probes"
}

# Allow internal traffic within the VPC
resource "google_compute_firewall" "allow_internal" {
  name    = "${var.project_name}-allow-internal"
  network = google_compute_network.main.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [google_compute_subnetwork.main.ip_cidr_range]
  description   = "Allow internal VPC traffic"
}

# Deny all other ingress (explicit, overrides GCP default allow)
resource "google_compute_firewall" "deny_all_ingress" {
  name    = "${var.project_name}-deny-all-ingress"
  network = google_compute_network.main.name

  deny {
    protocol = "all"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 65534
  description   = "Default deny all ingress"
}

# VPC connector — allows Cloud Run to reach private Cloud SQL and other VPC resources
resource "google_vpc_access_connector" "main" {
  name          = "${var.project_name}-vpc-connector"
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.main.name
}

