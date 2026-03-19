terraform {
  backend "gcs" {
    bucket = "docuvault-prod-terraform-state"
    prefix = "production"
  }
}

