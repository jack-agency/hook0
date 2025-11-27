output "api_service_url" {
  description = "The URL at which the Cloud Run service is accessible"
  value       = google_cloud_run_v2_service.hook0_api.urls[0]
}

output "api_neg_id" {
  description = "The ID of the Cloud Run service NEG"
  value       = google_compute_region_network_endpoint_group.hook0_api_neg.id
}

output "api_neg_self_link" {
  description = "The self link of the Cloud Run service NEG"
  value       = google_compute_region_network_endpoint_group.hook0_api_neg.self_link
  
}