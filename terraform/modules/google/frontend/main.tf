## Create the Cloud Run service for the Frontend.

resource "google_cloud_run_v2_service" "hook0_frontend" {
  name                = "hook0-frontend"
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      image = var.frontend_image

      ports {
        container_port = var.frontend_container_port
      }

      env {
        name  = "API_ENDPOINT"
        value = "http://localhost:8081/api/v1" # Only for test purposes. To replace with the API service URL in production.
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
