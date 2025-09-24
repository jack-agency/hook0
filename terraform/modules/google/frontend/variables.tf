variable "project_id" {
  description = "The project ID to work in"
  type        = string
}

variable "region" {
  description = "The region to to deploy ressources in"
  type        = string
  default     = "europe-west1"
}

variable "frontend_service_name" {
  description = "The name of the Cloud Run service"
  type        = string
}

variable "frontend_image" {
  description = "The fully qualified image URL to deploy from Artifact Registry"
  type        = string
}

variable "frontend_container_port" {
  description = "The container port on which the API listens"
  type        = number
  default     = 80
}

variable "frontend_service_account_email" {
  description = "The email of the service account to run the Cloud Run service as"
  type        = string
}

variable "api_service_name" {
  description = "The name of the Cloud Run API service"
  type        = string
}

variable "vpc_connector" {
  description = "The id of the serverless VPC Access connector"
  type        = string
}
