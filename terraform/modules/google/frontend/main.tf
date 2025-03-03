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
    }

    vpc_access {
      connector = var.vpc_connector
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }
}
