terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.46"
    }
  }
}

provider "google" {
  project = "docuvault-prod-385212"
  region  = "us-central1"
  zone    = "us-central1-a"

  default_labels = {
    project     = "docuvault"
    environment = "production"
    managed-by  = "terraform"
    team        = "platform"
  }
}

