## Create the Cloud Run service for the Frontend.

data "google_project" "main" {
  project_id = var.project_id
}

resource "google_cloud_run_v2_service" "hook0_frontend" {
  name                = "hook0-frontend"
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  # launch_stage = "BETA"
  # provider = google-beta
  # iap_enabled = true

  template {
    service_account = var.frontend_service_account_email

    containers {
      image = var.frontend_image

      ports {
        container_port = var.frontend_container_port
      }

      env {
        name  = "API_ENDPOINT"
        value = "https://${var.api_service_name}-${data.google_project.main.number}.${var.region}.run.app/api/v1" # The API endpoint URL
      }
    }

    vpc_access {
      # connector = var.vpc_connector
      egress = "PRIVATE_RANGES_ONLY"

      network_interfaces {
        network    = "lucius"
        subnetwork = "lucius"
        tags       = ["smtp"]
      }
    }
  }
}

# Adding NEG for Load Balancer integration.
resource "google_compute_region_network_endpoint_group" "hook0_frontend_neg" {
  name        = "${var.frontend_service_name}-neg"
  region      = var.region
  project     = var.project_id
  network_endpoint_type = "SERVERLESS"
  cloud_run {
    service = google_cloud_run_v2_service.hook0_frontend.name
  }
  lifecycle {
    create_before_destroy = true
  }

  depends_on = [ google_cloud_run_v2_service.hook0_frontend ]
}
