output "cloud_run_api_sa_email" {
  description = "The email of the service account used by the API Cloud Run Service."
  value       = google_service_account.cloud_run_api_sa.email
}