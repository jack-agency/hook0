terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.18.1"
    }

    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.18.1"
    }
  }
}
