## Cloud Run service for the API.

resource "google_cloud_run_v2_service" "hook0_api" {
  name                = var.api_service_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"
  template {

    service_account = var.api_service_account_email

    containers {
      image = var.api_image
      ports {
        container_port = var.api_container_port
      }


      env {
        name = "DATABASE_URL"
        value_source {
          secret_key_ref {
            secret  = var.database_url
            version = "latest"
          }
        }
      }

      env {
        name  = "IP"
        value = "0.0.0.0"
      }

      env {
        name = "EMAIL_SENDER_ADDRESS"
        value_source {
          secret_key_ref {
            secret  = var.email_sender_address
            version = "latest"
          }
        }
      }

      env {
        name = "SMTP_CONNECTION_URL"
        value_source {
          secret_key_ref {
            secret  = var.smtp_connection_url
            version = "latest"
          }
        }
      }

      env {
        name  = "APP_URL"
        value = var.frontend_service_url
      }

      env {
        name  = "CORS_ALLOWED_ORIGINS"
        value = "${var.frontend_service_url},http://127.0.0.1:8080"
      }

      env {
        name = "BISCUIT_PRIVATE_KEY"
        value_source {
          secret_key_ref {
            secret  = var.biscuit_private_key
            version = "latest"
          }
        }
      }

      dynamic "env" {
        for_each = length(var.master_api_key) > 0 ? [var.master_api_key] : []
        content {
          name = "MASTER_API_KEY" # To remove in production. See https://documentation.hook0.com/docs/master-api-key.
          value_source {
            secret_key_ref {
              secret  = env.value
              version = "latest"
            }
          }
        }
      }
    }

    vpc_access {
      connector = var.vpc_connector
      egress    = "PRIVATE_RANGES_ONLY"
    }
  }

  depends_on = [var.biscuit_private_key, var.api_service_account_email, var.database_url, var.frontend_service_url]
}

## Cloud router and NAT to allow egress traffic to the SMTP server.

resource "google_compute_router" "hook0-smtp-router" {
  name    = "hook0-smtp-router"
  project = var.project_id
  region  = var.region
  network = var.vpc_network
}

resource "google_compute_router_nat" "hook0-smtp-nat" {
  name                               = "nat"
  project                            = var.project_id
  region                             = var.region
  router                             = google_compute_router.hook0-smtp-router.name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}
