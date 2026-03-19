terraform {
  backend "gcs" {
    bucket = "docuvault-dev-terraform-state"
    prefix = "development"
  }
}

