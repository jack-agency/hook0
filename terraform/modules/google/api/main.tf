## Cloud Run service for the API.
data "google_project" "main" {
  project_id = var.project_id
}

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
      depends_on = [ "cloud-sql-proxy" ]

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
        name  = "CORS_ALLOWED_ORIGINS"
        value = "http://localhost:8081,http://localhost:8082" # Only for test purposes.
      }

      env {
        name  = "APP_URL"
        value = "http://localhost:8082" # Only for test purposes. To replace with the frontend service URL in production.
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

    containers {
      name = "cloud-sql-proxy"

      image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.13.0"
      args = flatten([
        # "--auto-iam-authn",
        "--address", "0.0.0.0",
        "--private-ip",
        "--health-check",
        "--http-address", "0.0.0.0",
        # "--quiet",
        var.database_connection_name,
      ])

      startup_probe {
        http_get {
          path = "/startup"
          port = 9090
        }
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

  depends_on = [var.biscuit_private_key, var.api_service_account_email, var.database_url, var.frontend_service_url]
}

resource "google_compute_firewall" "allow_smtp" {
  name    = "lucius-allow-smtp"
  network = var.vpc_network

  direction   = "EGRESS"
  description = "Allow SMTP egress on secure ports 465 and 587."

  allow {
    protocol = "tcp"
    ports    = ["465", "587"]
  }

  target_tags        = ["smtp"]
  destination_ranges = ["0.0.0.0/0"]
}

## Cloud router and NAT to allow egress traffic to the SMTP server.

# resource "google_compute_router" "hook0-smtp-router" {
#   name    = "hook0-smtp-router"
#   project = var.project_id
#   region  = var.region
#   network = var.vpc_network
# }

# resource "google_compute_router_nat" "hook0-smtp-nat" {
#   name                               = "nat"
#   project                            = var.project_id
#   region                             = var.region
#   router                             = google_compute_router.hook0-smtp-router.name
#   source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#   nat_ip_allocate_option             = "AUTO_ONLY"
# }
