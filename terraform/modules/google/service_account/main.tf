resource "google_service_account" "cloud_run_api_sa" {
  account_id   = "hook0-cloud-run"
  display_name = "Service Account for Hook0 API Cloud Run Service"
  project      = var.project_id
}
