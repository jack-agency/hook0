## Cloud Run service for the Output Worker.

resource "google_cloud_run_v2_service" "hook0_output_worker" {
  name                = var.output_worker_service_name
  location            = var.region
  project             = var.project_id
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  template {

    service_account = var.output_worker_service_account_email

    scaling {
      min_instance_count = 1
      max_instance_count = 1
    }

    containers {
      image = var.output_worker_image
      depends_on = [ "cloud-sql-proxy" ]

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
        name  = "WORKER_NAME"
        value = "default"
      }

      env {
        name  = "DISABLE_TARGET_IP_CHECK"
        value = false
      }
    }

    containers {
      image = "hashicorp/http-echo:0.2.3"
      name  = "output-worker-health-proxy"
      args  = ["-text=OK", "-listen=:${var.output_worker_container_port}"]

      ports {
        container_port = var.output_worker_container_port
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

    # VPC connector to allow access to private cloud sql in the VPC.
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

  depends_on = [var.output_worker_service_account_email, var.database_url]
}
