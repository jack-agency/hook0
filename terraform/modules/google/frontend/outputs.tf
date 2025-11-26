output "frontend_service_url" {
  description = "The URL at which the Cloud Run service is accessible"
  value       = google_cloud_run_v2_service.hook0_frontend.urls[0]
}

output "frontend_neg_id" {
  description = "The ID of the Cloud Run service NEG"
  value       = google_compute_region_network_endpoint_group.hook0_frontend_neg.id
  
}