output "frontend_service_url" {
  description = "The URL at which the Cloud Run service is accessible"
  value       = module.frontend_cloud_run.frontend_service_url
}

output "frontend_neg_id" {
  description = "The ID of the Cloud Run service NEG"
  value       = module.frontend_cloud_run.frontend_neg_id
}

output "api_service_url" {
  description = "The URL at which the API Cloud Run service is accessible"
  value       = module.api_cloud_run.api_service_url
}

output "api_neg_id" {
  description = "The ID of the API Cloud Run service NEG"
  value       = module.api_cloud_run.api_neg_id
}