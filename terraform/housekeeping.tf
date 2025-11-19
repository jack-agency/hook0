## Cloud Run Job for housekeeping

resource "google_cloud_run_v2_job" "housekeeping" {
  project  = var.project_id
  location = var.region
  name     = var.housekeeping_job_name

  template {
    template {
      containers {
        image = data.google_artifact_registry_docker_image.hook0_api.self_link
        args  = ["--run-housekeeping", "--housekeeping-delete=${var.housekeeping_delete}", "--housekeeping-full-reindex=${var.housekeeping_full_reindex}"]

        env {
          name  = "DATABASE_URL"
          value = module.secrets.db_connection_string
        }
      }

      service_account = module.api_service_account.cloud_run_api_sa_email
    }
  }

  depends_on = [module.api_service_account]
}

## Cloud Scheduler to trigger the job
resource "google_cloud_scheduler_job" "housekeeping_trigger" {
  project = var.project_id
  name    = "${var.housekeeping_job_name}-trigger"
  description = "Trigger Cloud Run Job to run housekeeping"
  region  = var.region
  schedule = var.housekeeping_cron
  time_zone = var.housekeeping_time_zone

  http_target {
    http_method = "POST"
    uri = "https://run.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/jobs/${google_cloud_run_v2_job.housekeeping.name}:run"

    oauth_token {
      service_account_email = module.api_service_account.cloud_run_api_sa_email
    }
  }

  depends_on = [google_cloud_run_v2_job.housekeeping]
}

## Grant the Cloud Run Job run permission to the service account used by Cloud Scheduler
resource "google_project_iam_member" "housekeeping_sa_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${module.api_service_account.cloud_run_api_sa_email}"

  depends_on = [google_cloud_run_v2_job.housekeeping]
}
